"""Фоновые задачи: напоминания ученикам, недельный дайджест и сигналы учителю.

Как это работает: раз в минуту бот проверяет время. Что уже отправлено, записывается в таблицу job_runs,
поэтому после перезапуска бота ничего не уйдёт повторно, а пропущенное (если бот был выключен в нужный час)
будет отправлено, как только он снова заработает, но только в разумное время суток."""
import asyncio
import json
import logging
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from html import escape as esc

from aiogram import Bot
from aiogram.exceptions import TelegramForbiddenError
from aiogram.types import InlineKeyboardButton, InlineKeyboardMarkup

import analytics as an
import db


@dataclass
class Config:
    tz: object = None
    day_start_hour: int = 5      # с какого часа начинается «день» бота
    remind_hour: int = 18        # во сколько напоминать ученикам
    quiet_from: int = 21         # после этого часа напоминания не отправляем
    digest_weekday: int = 0      # 0 = понедельник
    digest_hour: int = 9         # во сколько присылать дайджест и сигналы учителю
    teachers: set = field(default_factory=set)
    pause_after: int = 3         # столько напоминаний подряд без единого ответа → пауза до возвращения


def bot_today(now, cfg):
    return (now - timedelta(hours=cfg.day_start_hour)).date()


def ikb(*rows):
    return InlineKeyboardMarkup(inline_keyboard=[
        [InlineKeyboardButton(text=t, callback_data=c) for t, c in row] for row in rows])


# =====================================================================================
#  Напоминания ученикам
# =====================================================================================
def build_reminder(con, u, today, cfg):
    """Собирает одно напоминание для ученика или возвращает None, если напоминать не о чем.
    Возвращает (текст, клавиатура, ключи_дедлайнов, есть_квиз)."""
    ch = db.get_character(con, u["id"])
    lines, rows, stages = [], [], []
    last_answer = con.execute("SELECT MAX(day) FROM events WHERE user_id=? AND event_type='answer'",
                              (u["id"],)).fetchone()[0]
    recent = bool(last_answer) and (today - date.fromisoformat(last_answer)).days <= 3
    streak = db.effective_streak(ch, today)
    ignored = con.execute(
        "SELECT COUNT(*) FROM events WHERE user_id=? AND event_type='reminder' AND context='quiz' AND ts > "
        "COALESCE((SELECT MAX(ts) FROM events WHERE user_id=? AND event_type='answer'), '')",
        (u["id"], u["id"])).fetchone()[0]
    has_quiz = False
    if db.daily_status(con, u["id"], today) != "done" and (recent or streak >= 2) and ignored < cfg.pause_after:
        has_quiz = True
        lines.append(f"🔥 Серия {streak} дн. ждёт квиза: не дай ей сгореть!" if streak >= 2
                     else "🎯 Квиз дня ждёт тебя: пара минут, и день засчитан.")
        rows.append([("🎯 Начать квиз", "rem:quiz")])
    for hw in db.homework_for_user(con, u):
        if (hw["status"] or "new") in ("done", "submitted") or not hw["due_date"]:
            continue
        delta = (date.fromisoformat(hw["due_date"]) - today).days
        stage = {0: "today", 1: "tomorrow"}.get(delta)
        key = f"{u['id']}:{hw['id']}:{stage}"
        if stage and not db.job_done(con, "hwremind", key):
            lines.append(f"📝 {'Сегодня' if stage == 'today' else 'Завтра'} дедлайн: «{esc(hw['title'][:50])}»")
            rows.append([(f"📝 Открыть: {hw['title'][:28]}", f"hw:open:{hw['id']}")])
            stages.append(key)
    if not lines:
        return None
    return "\n".join(lines), ikb(*rows[:4]), stages, has_quiz


async def send_reminders(bot: Bot, con, today, cfg):
    sent = 0
    for u in con.execute("SELECT * FROM users WHERE role='student' AND is_active=1 AND remind=1").fetchall():
        key = f"{u['id']}:{today.isoformat()}"
        if db.job_done(con, "remind", key):
            continue
        built = build_reminder(con, u, today, cfg)
        if not built:
            continue
        text, kb, stages, has_quiz = built
        try:
            await bot.send_message(u["telegram_id"], text, reply_markup=kb)
        except TelegramForbiddenError:          # ученик заблокировал бота: больше не беспокоим
            db.set_remind(con, u["id"], False)
            logging.info("Ученик %s заблокировал бота, напоминания выключены", u["nickname"])
            continue
        except Exception:
            logging.warning("Не удалось отправить напоминание %s", u["nickname"], exc_info=True)
            continue
        db.job_mark(con, "remind", key)
        for s in stages:
            db.job_mark(con, "hwremind", s)
        db.log_event(con, u["id"], "reminder", today, context="quiz" if has_quiz else "hw",
                     extra=json.dumps({"quiz": has_quiz, "hw": len(stages)}))
        sent += 1
        await asyncio.sleep(0.05)               # не превышаем лимиты Telegram
    return sent


# =====================================================================================
#  Дайджест и сигналы учителю
# =====================================================================================
async def _to_teachers(bot: Bot, cfg, text, kb=None):
    delivered = 0
    for tid in cfg.teachers:
        try:
            chunks = an.split_text(text)
            for i, chunk in enumerate(chunks):
                await bot.send_message(tid, chunk, reply_markup=kb if i == len(chunks) - 1 else None)
            delivered += 1
        except Exception:
            logging.warning("Не удалось отправить сообщение учителю %s (он писал боту /start?)", tid, exc_info=True)
    return delivered


async def send_digest(bot: Bot, con, today, cfg):
    text = an.build_digest(con, today)
    flags = an.risk_flags(con, today)
    kb = ikb([("⚠️ Кому нужно внимание", "tp:flags")]) if flags else None
    delivered = await _to_teachers(bot, cfg, text, kb)
    for uid, fl in flags.items():               # эти сигналы учитель уже увидел в дайджесте
        for f in fl:
            db.job_mark(con, "flag", f"{uid}:{f[2]}")
    return delivered


async def send_flag_alerts(bot: Bot, con, today, cfg):
    """Раз в день присылает только НОВЫЕ сигналы (одно и то же предупреждение дважды не повторяется)."""
    names = {r["id"]: r["nickname"] for r in con.execute("SELECT id, nickname FROM users")}
    fresh = {}
    for uid, fl in an.risk_flags(con, today).items():
        new = [f for f in fl if not db.job_done(con, "flag", f"{uid}:{f[2]}")]
        if new:
            fresh[uid] = new
    if not fresh:
        return 0
    lines = ["⚠️ <b>Новые сигналы</b>"] + [f"• {esc(names[uid])} — {esc(an.flags_text(fl))}"
                                          for uid, fl in list(fresh.items())[:15]]
    if len(fresh) > 15:
        lines.append(f"…и ещё {len(fresh) - 15}")
    delivered = await _to_teachers(bot, cfg, "\n".join(lines), ikb([("⚠️ Открыть список", "tp:flags")]))
    for uid, fl in fresh.items():
        for f in fl:
            db.job_mark(con, "flag", f"{uid}:{f[2]}")
    return delivered


# =====================================================================================
#  Тик планировщика
# =====================================================================================
def enabled(con, name):
    return db.get_setting(con, name, "1") == "1"


async def tick(bot: Bot, con, now: datetime, cfg: Config):
    """Одна проверка времени. Возвращает список выполненных задач (для тестов и логов)."""
    done, today, hour = [], bot_today(now, cfg), now.hour
    if enabled(con, "reminders") and cfg.remind_hour <= hour < cfg.quiet_from \
            and not db.job_done(con, "reminders", today.isoformat()):
        n = await send_reminders(bot, con, today, cfg)
        db.job_mark(con, "reminders", today.isoformat())
        done.append(f"reminders:{n}")
    if cfg.teachers and cfg.digest_hour <= hour < 22:
        week = an._iso_week(now.date())
        if enabled(con, "digest") and now.weekday() == cfg.digest_weekday and not db.job_done(con, "digest", week):
            n = await send_digest(bot, con, today, cfg)
            db.job_mark(con, "digest", week)
            done.append(f"digest:{n}")
        if enabled(con, "flags") and not db.job_done(con, "flagcheck", today.isoformat()):
            n = await send_flag_alerts(bot, con, today, cfg)
            db.job_mark(con, "flagcheck", today.isoformat())
            if n:
                done.append(f"flags:{n}")
    return done


async def run(bot: Bot, con, cfg: Config, interval=60):
    logging.info("Планировщик запущен: напоминания в %s:00, дайджест по дню недели %s в %s:00",
                 cfg.remind_hour, cfg.digest_weekday, cfg.digest_hour)
    while True:
        try:
            await tick(bot, con, datetime.now(cfg.tz), cfg)
        except Exception:
            logging.exception("Ошибка планировщика (продолжаю работу)")
        await asyncio.sleep(interval)
