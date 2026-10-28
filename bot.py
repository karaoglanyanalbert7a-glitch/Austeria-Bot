"""Telegram-бот для геймификации обучения английскому. Версия 1.3."""
import asyncio
import json
import logging
import os
import re
import sqlite3
import tempfile
import time
from datetime import datetime, timedelta
from html import escape as esc
from zoneinfo import ZoneInfo

from collections import Counter

from aiogram import Bot, Dispatcher, F, Router
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
from aiogram.exceptions import TelegramBadRequest
from aiogram.filters import Command, CommandStart
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.fsm.storage.memory import MemoryStorage, SimpleEventIsolation
from aiogram.types import (BotCommand, BotCommandScopeChat, CallbackQuery, ErrorEvent, InlineKeyboardButton,
                           InlineKeyboardMarkup, KeyboardButton, Message, ReplyKeyboardMarkup)
from aiogram.types import FSInputFile
from dotenv import load_dotenv

import analytics as an
import db
import scheduler as sch

load_dotenv("settings.env")
TOKEN = os.getenv("BOT_TOKEN", "").strip()
TEACHERS = {int(x) for x in os.getenv("TEACHER_IDS", "").replace(" ", "").split(",") if x}
TZ = ZoneInfo(os.getenv("TIMEZONE", "Europe/Amsterdam"))
DATA_DIR = os.getenv("DATA_DIR", "").strip()   # на хостинге это /app/data: единственная папка, которая переживает обновления
DB_PATH = os.getenv("DB_PATH", "").strip() or (os.path.join(DATA_DIR, "bot.db") if DATA_DIR else "bot.db")
QUIZ_SIZE = int(os.getenv("QUIZ_SIZE", "5"))
DAY_START_HOUR = int(os.getenv("DAY_START_HOUR", "5"))   # с этого часа начинается новый «день» бота
SCHED = sch.Config(tz=TZ, day_start_hour=DAY_START_HOUR, remind_hour=int(os.getenv("REMIND_HOUR", "18")),
                   digest_weekday=int(os.getenv("DIGEST_WEEKDAY", "0")), digest_hour=int(os.getenv("DIGEST_HOUR", "9")),
                   teachers=TEACHERS)
WEEKDAYS = ["понедельникам", "вторникам", "средам", "четвергам", "пятницам", "субботам", "воскресеньям"]
QUESTIONS_FILE = "questions.xlsx"

os.makedirs(os.path.dirname(os.path.abspath(DB_PATH)), exist_ok=True)
con = db.connect(DB_PATH)
router = Router()
teacher = Router()
teacher.message.filter(F.from_user.id.in_(TEACHERS))
teacher.callback_query.filter(F.from_user.id.in_(TEACHERS))


def today():
    """Текущий «день» бота: новый день наступает в DAY_START_HOUR утра, а не в полночь.
    Так квиз, начатый поздно вечером, не обнуляется ровно в 00:00."""
    return (datetime.now(TZ) - timedelta(hours=DAY_START_HOUR)).date()


class Reg(StatesGroup):
    nickname = State()


class Quiz(StatesGroup):
    text_answer = State()


class NewHW(StatesGroup):      # мастер создания задания (учитель)
    title = State()
    desc = State()
    comment = State()
    search = State()


class Submit(StatesGroup):     # ученик сдаёт авторское задание
    waiting = State()


class NewGroup(StatesGroup):   # ввод названия группы (создание / переименование)
    name = State()


class RW(StatesGroup):         # ввод своего числа или причины в наградах
    amount = State()
    reason = State()


BTN_QUIZ, BTN_PROFILE, BTN_MEMO, BTN_HW = "🎯 Квиз", "👤 Профиль", "📖 Памятки", "📝 Домашка"
BTN_STUDENTS, BTN_NEWHW = "👥 Ученики", "➕ Новое задание"     # BTN_NEWHW: только для старых клавиатур
BTN_GROUPS, BTN_TASKS, BTN_REWARDS, BTN_PANEL = "🏷 Группы", "📝 Задания", "🎁 Награды", "📊 Сводка"
MENU_STUDENT = ReplyKeyboardMarkup(
    keyboard=[[KeyboardButton(text=BTN_QUIZ), KeyboardButton(text=BTN_PROFILE)],
              [KeyboardButton(text=BTN_MEMO), KeyboardButton(text=BTN_HW)]], resize_keyboard=True)
MENU_TEACHER = ReplyKeyboardMarkup(
    keyboard=[[KeyboardButton(text=BTN_STUDENTS), KeyboardButton(text=BTN_GROUPS)],
              [KeyboardButton(text=BTN_TASKS), KeyboardButton(text=BTN_REWARDS)],
              [KeyboardButton(text=BTN_PANEL)]], resize_keyboard=True)

TEACHER_HELP = (
    "<b>Команды учителя.</b> Всё это можно делать кнопками внизу; команды нужны для быстрых действий. "
    "Ник пишется без учёта регистра, название группы может содержать пробелы.\n\n"
    "<b>Группы и ученики</b>\n"
    "/addgroup название [A1|A2|B1|B2|C1] — создать группу\n"
    "/groups — список групп\n"
    "/setgroup ник группа — перевести ученика (вместо группы «-» убирает из группы)\n"
    "/delgroup название — удалить пустую группу\n"
    "/students [группа] — список учеников\n"
    "/student ник — отчёт по ученику\n"
    "/group название — отчёт по группе: слабые темы и кто пропал\n\n"
    "<b>Награды и штрафы</b> (тип: xp, coins или freeze)\n"
    "/reward ник тип число [причина]\n"
    "/penalty ник coins|freeze число [причина]\n"
    "/rewardgroup группа тип число [причина]\n\n"
    "<b>Домашние задания</b>\n"
    "/newhw — создать задание (тест из банка или авторское)\n"
    "/hw — задания, кто сдал, закрыть задание\n"
    "/hwdone id ник — отметить выполненным (если приняли вне бота)\n"
    "/hwreset id ник — сбросить попытку ученика\n\n"
    "<b>Аналитика и данные</b>\n"
    "/digest — недельный дайджест сейчас\n"
    "/flags — кому нужно внимание (пропали, падает точность, просрочки)\n"
    "/mistakes — типичные ошибки (какие вопросы валят и какой ответ выбирают)\n"
    "/export — Excel-файл со всей статистикой\n"
    "/backup — прислать резервную копию базы файлом\n\n"
    "<b>Контент</b>\n"
    "Пришлите файл .xlsx: загрузятся вопросы (лист questions) и памятки (лист cheatsheets).")

def teacher_panel():
    """Сводка для учителя: показывается над списком команд."""
    s = db.teacher_overview(con, today())
    return (f"📊 <b>Сейчас:</b> учеников — {s['students']}, групп — {s['groups']} · сегодня занимались — "
            f"{s['active_today']} · активных заданий — {s['homeworks']} · ждут проверки — {s['pending']}\n\n")


STUDENT_COMMANDS = [BotCommand(command="quiz", description="Начать квиз"),
                    BotCommand(command="profile", description="Мой профиль"),
                    BotCommand(command="memo", description="Памятки по темам"),
                    BotCommand(command="hw", description="Домашние задания"),
                    BotCommand(command="help", description="Помощь")]
TEACHER_COMMANDS = [BotCommand(command="hw", description="Задания и кто сдал"),
                    BotCommand(command="newhw", description="Создать задание"),
                    BotCommand(command="students", description="Список учеников"),
                    BotCommand(command="digest", description="Недельный дайджест"),
                    BotCommand(command="groups", description="Группы"),
                    BotCommand(command="admin", description="Все команды")]


# ---------- мелкие помощники интерфейса ----------
def ikb(*rows):
    """Клавиатура под сообщением: ikb([("Текст", "данные"), ...], [...])."""
    return InlineKeyboardMarkup(inline_keyboard=[
        [InlineKeyboardButton(text=t, callback_data=c) for t, c in row] for row in rows])


async def tidy(m: Message):
    """Удаляет сообщение пользователя (нажатие кнопки, введённый ответ), чтобы чат оставался чистым."""
    try:
        await m.delete()
    except Exception:
        pass


async def edit(cb: CallbackQuery, text, kb=None):
    """Заменяет текст сообщения с кнопкой (вместо нового сообщения)."""
    try:
        await cb.message.edit_text(text, reply_markup=kb)
    except TelegramBadRequest as e:
        if "not modified" not in str(e).lower():
            await cb.message.answer(text, reply_markup=kb)


async def send_long(message: Message, text: str, **kw):
    """Telegram не принимает сообщения длиннее 4096 символов: режем по строкам."""
    chunk = ""
    for line in text.split("\n"):
        if len(chunk) + len(line) + 1 > 3500 and chunk:
            await message.answer(chunk, **kw)
            chunk = ""
        chunk += line + "\n"
    if chunk.strip():
        await message.answer(chunk.rstrip("\n"), **kw)


def memo_html(text):
    """Текст памятки: экранируем HTML, **жирный** превращаем в <b>."""
    return re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", esc(text))


def player(tg_id):
    return db.get_user_by_tg(con, tg_id)


def fmt_due(due):
    if not due:
        return "без дедлайна"
    y, mo, dd = due.split("-")
    return f"до {dd}.{mo}"


def is_overdue(due):
    return bool(due) and today().isoformat() > due


def hw_label(status, score, total, late, kind, due):
    st = status or "new"
    if st == "done":
        base = f"✅ {score}/{total}" if kind == "quiz" and total else "✅ принято"
        return base + (" (поздно)" if late else "")
    if st == "submitted":
        return "📤 на проверке"
    if st == "rework":
        return "🔁 доработать"
    if is_overdue(due):
        return "⚠️ просрочено"
    return "▶️ в процессе" if st == "in_progress" else "🆕 новое"


# ======================= регистрация =======================
NICK_RE = re.compile(r"[\w\-]{2,20}")   # буквы (русские и английские), цифры, _ и -


def nick_problem(nick):
    """(текст ошибки, предложенный_ник) или (None, None), если никнейм подходит."""
    if re.search(r"\s", nick):
        fixed = re.sub(r"\s+", "_", nick.strip())
        return (f"Пробелы в никнейме нельзя 🙂 Вместо пробела используй <b>_</b> или <b>-</b>, "
                f"например: <b>{esc(fixed[:20])}</b>"), fixed
    if len(nick) < 2:
        return "Слишком короткий никнейм: нужно минимум 2 символа.", None
    if len(nick) > 20:
        return "Слишком длинный никнейм: максимум 20 символов.", None
    if not NICK_RE.fullmatch(nick):
        return ("В никнейме можно использовать только буквы (русские или английские), цифры, _ и -. "
                "Точки, смайлики и другие знаки нельзя."), None
    if db.get_user_by_nick(con, nick):
        return "Такой никнейм уже занят. Придумай другой.", None
    return None, None


async def register_student(tg_id, nick, state: FSMContext, message: Message):
    await state.clear()
    if not player(tg_id):
        uid = db.create_user(con, tg_id, nick)
        db.log_event(con, uid, "register", today())
    await message.answer(
        f"Готово, <b>{esc(nick)}</b>! Твой персонаж создан 🎉\n\n"
        "🎯 <b>Квиз</b> — короткие вопросы каждый день: получаешь XP и растёшь по уровням от A1 до C1\n"
        "🔥 Заходи каждый день, чтобы не терять серию\n"
        "📖 <b>Памятки</b> — правила по темам\n"
        "📝 <b>Домашка</b> — задания от учителя\n"
        "🔔 Иногда я буду напоминать о квизе и дедлайнах (отключить можно в «Профиле»)\n\n"
        "Нажми «🎯 Квиз», чтобы начать!", reply_markup=MENU_STUDENT)


@router.message(CommandStart())
async def cmd_start(m: Message, state: FSMContext):
    await state.clear()
    u = player(m.from_user.id)
    if u:
        await m.answer(f"С возвращением, <b>{esc(u['nickname'])}</b>! Жми «Квиз» и качай персонажа.",
                       reply_markup=MENU_STUDENT)
        return
    await state.set_state(Reg.nickname)
    await m.answer("Привет! Давай создадим твоего персонажа 🎮\n\nПридумай <b>никнейм</b>: 2–20 символов, "
                   "буквы (русские или английские), цифры, _ и -. Без пробелов. "
                   "Настоящее имя писать не нужно.")


@router.message(Reg.nickname, F.text, ~F.text.startswith("/"))
async def reg_nickname(m: Message, state: FSMContext):
    nick = m.text.strip()
    problem, fixed = nick_problem(nick)
    if problem:
        kb = None
        if fixed and not nick_problem(fixed)[0]:
            kb = ikb([(f"✅ Взять «{fixed}»", f"nick:{fixed}")])
        await m.answer(problem, reply_markup=kb)
        return
    await register_student(m.from_user.id, nick, state, m)


@router.callback_query(Reg.nickname, F.data.startswith("nick:"))
async def reg_nick_button(cb: CallbackQuery, state: FSMContext):
    nick = cb.data[5:]
    problem, _ = nick_problem(nick)
    await cb.answer()
    if problem:
        await cb.message.answer(problem)
        return
    try:
        await cb.message.edit_reply_markup(reply_markup=None)
    except Exception:
        pass
    await register_student(cb.from_user.id, nick, state, cb.message)


@router.message(Command("help"))
async def cmd_help(m: Message):
    await m.answer("🎯 <b>Квиз</b> — несколько вопросов, за ответы получаешь XP и монеты. "
                   "Первый квиз за день даёт больше всего XP и продлевает серию 🔥. "
                   "Незаконченный квиз живёт до конца дня, завтра будет новый.\n"
                   "👤 <b>Профиль</b> — твой уровень, серия и навыки.\n"
                   "📖 <b>Памятки</b> — краткие правила по темам.\n"
                   "📝 <b>Домашка</b> — задания от учителя.")


# ======================= профиль =======================
def bar(cur, total, width=10):
    filled = 0 if total <= 0 else max(0, min(width, round(width * cur / total)))
    return "█" * filled + "░" * (width - filled)


def profile_kb(remind):
    return ikb([(f"🔔 Напоминания: {'включены ✅' if remind else 'выключены 🔕'}", "rem:toggle")],
               [("✖️ Закрыть", "close")])


@router.message(Command("profile"))
@router.message(F.text == BTN_PROFILE)
async def profile(m: Message):
    u = player(m.from_user.id)
    await tidy(m)
    if not u:
        await m.answer("Сначала нажми /start")
        return
    ch = db.get_character(con, u["id"])
    lvl = ch["level"]
    grp = db.group_name(con, u["group_id"])
    lines = [f"👤 <b>{esc(u['nickname'])}</b>" + (f" · группа {esc(grp)}" if grp else ""),
             f"⭐ Уровень <b>{lvl}</b> · {db.cefr_for_level(lvl)}"]
    if lvl < db.MAX_LEVEL:
        lo, hi = db.xp_for_level(lvl), db.xp_for_level(lvl + 1)
        lines.append(f"XP: {ch['xp']}  {bar(ch['xp'] - lo, hi - lo)}  до уровня {lvl + 1}: {hi - ch['xp']}")
    else:
        lines.append(f"XP: {ch['xp']} (максимальный уровень!)")
    daily = {"done": "✅ пройден", "started": "⏳ начат, можно закончить («🎯 Квиз»)",
             "none": "🎯 ждёт тебя"}[db.daily_status(con, u["id"], today())]
    lines += [f"📅 Квиз дня: {daily}", f"🪙 Монеты: {ch['coins']}",
              f"🔥 Серия: {db.effective_streak(ch, today())} дн. · ❄️ заморозок: {ch['freezes']}",
              f"\n📚 Словарь: {ch['vocabulary']} · 🧩 Грамматика: {ch['grammar']}\n"
              f"🎧 Аудирование: {ch['listening']} · 🗣 Говорение: {ch['speaking']}"]
    total = con.execute("SELECT COUNT(*), COALESCE(SUM(is_correct),0) FROM events "
                        "WHERE user_id=? AND event_type='answer'", (u["id"],)).fetchone()
    if total[0]:
        lines.append(f"\n🎯 Точность: {round(100 * total[1] / total[0])}% (ответов: {total[0]})")
    db.log_event(con, u["id"], "profile_view", today())
    await m.answer("\n".join(lines), reply_markup=profile_kb(u["remind"]))


@router.callback_query(F.data == "close")
async def close_message(cb: CallbackQuery):
    await cb.answer()
    try:
        await cb.message.delete()
    except Exception:
        pass


# ======================= памятки =======================
def memo_list_content(page=0):
    sheets = db.list_cheatsheets(con)
    if not sheets:
        return "Памяток пока нет. Скоро появятся 🙂", None
    pages = max(1, -(-len(sheets) // PAGE))
    page = max(0, min(page, pages - 1))
    rows = [[(f"{x['topic'][:45]} · {x['cefr']}" if x["cefr"] else x["topic"][:50], f"memo:{x['id']}:{page}")]
            for x in sheets[page * PAGE:(page + 1) * PAGE]]
    rows += nav_row(page, pages, "memo:list")
    return "📖 <b>Памятки.</b> Выбери тему:" + (f" (страница {page + 1} из {pages})" if pages > 1 else ""), ikb(*rows)


@router.message(Command("memo"))
@router.message(F.text == BTN_MEMO)
async def memo_list(m: Message):
    u = player(m.from_user.id)
    await tidy(m)
    if not u:
        await m.answer("Сначала нажми /start")
        return
    text, kb = memo_list_content()
    await m.answer(text, reply_markup=kb)


@router.callback_query(F.data.startswith("memo:"))
async def memo_show(cb: CallbackQuery):
    p = cb.data.split(":")
    key, page = p[1], (int(p[2]) if len(p) > 2 else 0)
    await cb.answer()
    if key == "list":
        text, kb = memo_list_content(page)
        await edit(cb, text, kb)
        return
    s, u = db.get_cheatsheet(con, int(key)), player(cb.from_user.id)
    if not s or not u:
        return
    db.log_event(con, u["id"], "cheatsheet_view", today(), topic=s["topic"])
    text = f"📖 <b>{esc(s['topic'])}</b>\n\n{memo_html(s['text'])}"
    if len(text) <= 3900:
        await edit(cb, text, ikb([("⬅️ К списку", f"memo:list:{page}")]))
    else:
        await send_long(cb.message, text)


@router.callback_query(F.data.startswith("memq:"))
async def memo_from_quiz(cb: CallbackQuery):
    """Памятка из карточки квиза открывается отдельным сообщением, которое можно закрыть."""
    s, u = db.get_cheatsheet(con, int(cb.data.split(":")[1])), player(cb.from_user.id)
    await cb.answer()
    if not s or not u:
        return
    db.log_event(con, u["id"], "cheatsheet_view", today(), topic=s["topic"])
    text = f"📖 <b>{esc(s['topic'])}</b>\n\n{memo_html(s['text'])}"
    if len(text) <= 3900:
        await cb.message.answer(text, reply_markup=ikb([("✖️ Закрыть", "close")]))
    else:
        await send_long(cb.message, text)


# ======================= квиз: одна «карточка» на весь квиз =======================
def fresh(d):
    """Квиз живёт один день: на следующий день незаконченный квиз устаревает."""
    return bool(d.get("qids")) and d.get("day") == today().isoformat()


def q_header(d, q, pos):
    prefix = ""
    if d.get("hw_id"):
        hw = db.get_homework(con, d["hw_id"])
        prefix = f"📝 {esc(hw['title'])} · " if hw else ""
    tag = {"practice": " · 🏋️ тренировка", "homework_late": " · ⏰ после дедлайна"}.get(d["context"], "")
    return (f"<b>{prefix}Вопрос {pos + 1}/{len(d['qids'])}</b> · {esc(q['topic'])} · {q['cefr']}{tag}\n\n"
            f"{esc(q['question'])}")


async def drop_card(bot: Bot, chat_id, d):
    if d.get("card_id"):
        try:
            await bot.delete_message(chat_id, d["card_id"])
        except Exception:
            pass


async def render_card(bot: Bot, chat_id, state: FSMContext, text, kb=None, new=False):
    """Показывает карточку квиза: правит существующее сообщение (или создаёт новое)."""
    d = await state.get_data()
    cid = d.get("card_id")
    if cid and not new:
        try:
            await bot.edit_message_text(text, chat_id=chat_id, message_id=cid, reply_markup=kb)
            return
        except TelegramBadRequest as e:
            if "not modified" in str(e).lower():
                return
    elif cid:
        await drop_card(bot, chat_id, d)
    msg = await bot.send_message(chat_id, text, reply_markup=kb)
    await state.update_data(card_id=msg.message_id)


async def send_question(bot: Bot, chat_id, state: FSMContext, note="", new=False):
    d = await state.get_data()
    if not d.get("qids") or d["pos"] >= len(d["qids"]):
        await bot.send_message(chat_id, "Этот квиз уже закрыт. Нажми «🎯 Квиз», чтобы начать новый.")
        return
    q = db.get_question(con, d["qids"][d["pos"]])
    head = note + q_header(d, q, d["pos"])
    await state.update_data(shown_at=time.time(), phase="q")
    if q["type"] == "choice":
        letters = [l for l in "abcd" if q[f"option_{l}"]]
        body = "\n".join(f"<b>{l.upper()})</b> {esc(q['option_' + l])}" for l in letters)
        kb = ikb([(l.upper(), f"ans:{q['id']}:{d['pos']}:{l}") for l in letters])
        await state.set_state(None)
        await render_card(bot, chat_id, state, f"{head}\n\n{body}", kb, new=new)
    else:
        await state.set_state(Quiz.text_answer)
        await render_card(bot, chat_id, state, f"{head}\n\n✍️ Напиши ответ одним сообщением.", None, new=new)


async def launch_quiz(bot: Bot, chat_id, tg_id, state: FSMContext):
    """Запускает или продолжает квиз дня: кнопкой «Квиз» или кнопкой из напоминания."""
    u = player(tg_id)
    if not u:
        await bot.send_message(chat_id, "Сначала нажми /start")
        return
    d = await state.get_data()
    if fresh(d) and d["pos"] < len(d["qids"]):  # незаконченный квиз сегодняшнего дня: продолжаем
        note = ("↩️ <i>Продолжаем незаконченную домашку</i>\n\n" if d.get("hw_id")
                else "↩️ <i>Продолжаем незаконченный квиз</i>\n\n")
        await send_question(bot, chat_id, state, note=note, new=True)
        return
    await drop_card(bot, chat_id, d)  # вчерашняя карточка больше не нужна
    ch = db.get_character(con, u["id"])
    qs = db.pick_questions(con, u["id"], ch["level"], QUIZ_SIZE)
    if not qs:
        await bot.send_message(chat_id, "Пока нет вопросов. Попроси учителя загрузить их 🙂")
        return
    ctx = "practice" if db.daily_started_today(con, u["id"], today()) else "daily"
    await state.set_state(None)
    await state.set_data({"qids": [q["id"] for q in qs], "pos": 0, "correct": 0, "xp": 0, "coins": 0,
                          "context": ctx, "lvl0": ch["level"], "shown_at": time.time(),
                          "day": today().isoformat(), "card_id": None, "phase": "q"})
    db.log_event(con, u["id"], "quiz_start", today(), context=ctx)
    note = ("<i>Ежедневный квиз ты уже проходил(а): это дополнительная тренировка "
            "(XP меньше, но данные о прогрессе копятся) 💪</i>\n\n" if ctx == "practice" else "")
    await send_question(bot, chat_id, state, note=note, new=True)


@router.message(Command("quiz"))
@router.message(F.text == BTN_QUIZ)
async def start_quiz(m: Message, state: FSMContext):
    await tidy(m)
    await launch_quiz(m.bot, m.chat.id, m.from_user.id, state)


@router.callback_query(F.data == "rem:quiz")
async def reminder_quiz(cb: CallbackQuery, state: FSMContext):
    """Кнопка «Начать квиз» в напоминании: убираем напоминание и сразу открываем квиз."""
    await cb.answer()
    try:
        await cb.message.delete()
    except Exception:
        pass
    await launch_quiz(cb.bot, cb.message.chat.id, cb.from_user.id, state)


@router.callback_query(F.data == "rem:toggle")
async def reminder_toggle(cb: CallbackQuery):
    u = player(cb.from_user.id)
    if not u:
        await cb.answer()
        return
    new = 0 if u["remind"] else 1
    db.set_remind(con, u["id"], new)
    await cb.answer("🔔 Напоминания включены" if new else "🔕 Напоминания выключены")
    try:
        await cb.message.edit_reply_markup(reply_markup=profile_kb(new))
    except TelegramBadRequest:
        pass


async def quiz_alive(cb: CallbackQuery, state: FSMContext, d: dict) -> bool:
    """Проверяет, что карточка не устарела; если устарела — убирает её."""
    if fresh(d):
        return True
    if d.get("qids"):
        text = ("Эта сессия устарела. Продолжи задание в «📝 Домашка»." if d.get("hw_id")
                else "Этот квиз устарел: квизы обновляются каждый день. Нажми «🎯 Квиз», чтобы начать новый.")
        await state.clear()
    else:
        text = "Этот квиз уже закрыт. Нажми «🎯 Квиз», чтобы начать новый."
    await cb.answer(text, show_alert=True)
    try:
        await cb.message.delete()
    except Exception:
        pass
    return False


@router.callback_query(F.data.startswith("ans:"))
async def on_choice(cb: CallbackQuery, state: FSMContext):
    _, qid, pos, letter = cb.data.split(":")
    d = await state.get_data()
    if not await quiz_alive(cb, state, d):
        return
    if (d.get("phase") != "q" or d["pos"] != int(pos) or d["qids"][d["pos"]] != int(qid)
            or d.get("card_id") != cb.message.message_id):
        await cb.answer("Этот вопрос уже закрыт")
        return
    await cb.answer()
    await process_answer(cb.bot, cb.message.chat.id, cb.from_user.id, state, letter)


@router.callback_query(F.data.startswith("nxt:"))
async def on_next(cb: CallbackQuery, state: FSMContext):
    d = await state.get_data()
    if not await quiz_alive(cb, state, d):
        return
    if (d.get("phase") != "fb" or d["pos"] != int(cb.data.split(":")[1])
            or d.get("card_id") != cb.message.message_id):
        await cb.answer()
        return
    await cb.answer()
    await send_question(cb.bot, cb.message.chat.id, state)


@router.message(Quiz.text_answer, F.text, ~F.text.startswith("/"),
                F.text.not_in({BTN_QUIZ, BTN_PROFILE, BTN_MEMO, BTN_HW}))
async def on_text_answer(m: Message, state: FSMContext):
    d = await state.get_data()
    await tidy(m)  # введённый ответ показывается в карточке, из чата убираем
    if not fresh(d):
        await drop_card(m.bot, m.chat.id, d)
        await state.clear()
        await m.answer("Этот квиз устарел: квизы обновляются каждый день. Нажми «🎯 Квиз», чтобы начать новый.")
        return
    if d.get("phase") != "q":
        return
    await process_answer(m.bot, m.chat.id, m.from_user.id, state, m.text)


async def process_answer(bot: Bot, chat_id, tg_id, state: FSMContext, given: str):
    d = await state.get_data()
    pos = d["pos"]
    last = pos + 1 >= len(d["qids"])
    await state.update_data(pos=pos + 1, phase="fb")  # сразу закрываем вопрос: двойной клик не засчитается
    await state.set_state(None)
    q, u = db.get_question(con, d["qids"][pos]), player(tg_id)
    ms = int((time.time() - d["shown_at"]) * 1000)
    ok = db.check_answer(q, given)
    ctx = d["context"]
    gain, coins = db.apply_answer(con, u["id"], ok, ctx, q["skill"])
    chosen = q["option_" + given] if q["type"] == "choice" else given.strip()[:80]   # что именно ответил ученик
    db.log_event(con, u["id"], "answer", today(), question_id=q["id"], topic=q["topic"], skill=q["skill"],
                 cefr=q["cefr"], is_correct=int(ok), response_time_ms=ms, context=ctx, answer_given=chosen)
    if d.get("hw_id"):
        db.hw_record_answer(con, d["hw_id"], u["id"], q["id"], ok)
    d2 = {**d, "correct": d["correct"] + int(ok), "xp": d["xp"] + gain, "coins": d["coins"] + coins}
    await state.update_data(correct=d2["correct"], xp=d2["xp"], coins=d2["coins"])

    shown = (f"{given.upper()}) {q['option_' + given]}" if q["type"] == "choice" else given.strip()[:60])
    lines = [q_header(d, q, pos), "", "✅ <b>Верно!</b>" if ok else "❌ <b>Не совсем.</b>",
             f"Твой ответ: {esc(shown)}"]
    if not ok:
        lines.append(f"Правильно: <b>{esc(db.correct_display(q))}</b>")
    if q["explanation"]:
        lines.append(f"💡 {esc(q['explanation'])}")
    lines.append(f"<i>+{gain} XP</i>")
    rows = []
    if not last:
        rows.append([("➡️ Дальше", f"nxt:{pos + 1}")])
    if not ok:
        sheet = db.get_cheatsheet_by_topic(con, q["topic"])
        if sheet:
            rows.append([("📖 Памятка по теме", f"memq:{sheet['id']}")])
    if last:  # итог квиза показываем в той же карточке
        lines += ["", "━━━━━━━━━━", finalize_quiz(u, d2)]
    await render_card(bot, chat_id, state, "\n".join(lines), ikb(*rows) if rows else None)
    if last:
        await state.clear()


def finalize_quiz(u, d) -> str:
    """Подводит итог квиза или домашки: статус, серия, бонусы. Возвращает текст итога."""
    hw_id = d.get("hw_id")
    if hw_id:
        hw = db.get_homework(con, hw_id)
        correct, _ = db.hw_answers_summary(con, hw_id, u["id"])
        total = len(db.hw_question_ids(con, hw_id))
        late = d["context"] == "homework_late"
        db.hw_set_status(con, hw_id, u["id"], "done", score=correct, total=total, late=int(late),
                         completed_at=db.utc_now())
        db.log_event(con, u["id"], "hw_complete", today(), context=d["context"],
                     extra=json.dumps({"hw_id": hw_id, "correct": correct, "total": total}))
        bonus = 0 if late else db.adjust(con, u["id"], "xp", db.HW_QUIZ_BONUS_XP,
                                         "Бонус за домашку в срок", None, today())
        lines = [f"📝 <b>Домашка выполнена!</b> «{esc(hw['title'])}»", f"Верно: {correct}/{total}",
                 f"+{d['xp']} XP" + (f" · +{d['coins']} 🪙" if d["coins"] else "")]
        if bonus:
            lines.append(f"🎁 Бонус за выполнение в срок: +{bonus} XP")
        if late:
            lines.append("⏰ Сдано после дедлайна: бонус за срок не начислен.")
    else:
        n = len(d["qids"])
        db.log_event(con, u["id"], "quiz_complete", today(), context=d["context"],
                     extra=json.dumps({"correct": d["correct"], "total": n}))
        lines = [f"🏁 <b>Квиз завершён!</b> Верно: {d['correct']}/{n}",
                 f"+{d['xp']} XP" + (f" · +{d['coins']} 🪙" if d["coins"] else "")]
    streak, used, earned = db.update_streak(con, u["id"], today())
    ch = db.get_character(con, u["id"])
    if ch["level"] > d["lvl0"]:
        lines.append(f"🎉 <b>Новый уровень: {ch['level']}</b> ({db.cefr_for_level(ch['level'])})")
    lines.append(f"🔥 Серия: {streak} дн.")
    if used:
        lines.append("❄️ Заморозка спасла твою серию!")
    if earned:
        lines.append("🎁 +1 заморозка за 7 дней подряд!")
    return "\n".join(lines)


# ======================= домашние задания: ученик =======================
def hw_list_content(u):
    rows = db.homework_for_user(con, u)
    if not rows:
        return ("Заданий пока нет 🎉" + ("" if u["group_id"] else
                "\n(Если ждёшь задание, а его нет, попроси учителя добавить тебя в группу.)")), None
    return "📝 <b>Твои задания:</b>", ikb(*[[(
        f"{hw_label(r['status'], r['score'], r['total'], r['late'], r['kind'], r['due_date'])} · "
        f"{r['title'][:32]} · {fmt_due(r['due_date'])}", f"hw:open:{r['id']}")] for r in rows])


@router.message(Command("hw"))
@router.message(F.text == BTN_HW)
async def hw_list(m: Message):
    u = player(m.from_user.id)
    await tidy(m)
    if not u:
        await m.answer("Сначала нажми /start")
        return
    text, kb = hw_list_content(u)
    await m.answer(text, reply_markup=kb)


@router.callback_query(F.data == "hw:list")
async def hw_back(cb: CallbackQuery, state: FSMContext):
    if await state.get_state() == Submit.waiting.state:
        await state.set_state(None)
    await cb.answer()
    u = player(cb.from_user.id)
    if u:
        text, kb = hw_list_content(u)
        await edit(cb, text, kb)


def hw_card(hw, st, u):
    status = st["status"] if st else None
    label = hw_label(status, st["score"] if st else None, st["total"] if st else None,
                     st["late"] if st else 0, hw["kind"], hw["due_date"])
    lines = [f"📝 <b>{esc(hw['title'])}</b> · {fmt_due(hw['due_date'])}", f"Статус: {label}"]
    if hw["kind"] == "quiz":
        n = len(db.hw_question_ids(con, hw["id"]))
        lines.append(f"\nТест из {n} вопросов" + (f" по теме «{esc(hw['topic'])}»" if hw["topic"] else "")
                     + ". Проверяет бот, результат сразу.")
    elif hw["description"]:
        lines.append("\n" + esc(hw["description"]))
    if status == "rework" and st["teacher_comment"]:
        lines.append(f"\n💬 Комментарий учителя: {esc(st['teacher_comment'])}")
    rows = []
    if status != "done":
        if hw["kind"] == "quiz":
            left = len(db.hw_remaining(con, hw["id"], u["id"]))
            total = len(db.hw_question_ids(con, hw["id"]))
            rows.append([("▶️ Продолжить" if left < total else "▶️ Начать", f"hw:start:{hw['id']}")])
        else:
            rows.append([("📤 Отправить заново" if status in ("submitted", "rework") else "📤 Сдать работу",
                          f"hw:submit:{hw['id']}")])
    rows.append([("⬅️ К списку", "hw:list")])
    return "\n".join(lines), ikb(*rows)


@router.callback_query(F.data.startswith("hw:open:"))
async def hw_open(cb: CallbackQuery, state: FSMContext):
    if await state.get_state() == Submit.waiting.state:  # «Отмена» при сдаче работы
        await state.set_state(None)
    u, hw = player(cb.from_user.id), db.get_homework(con, int(cb.data.split(":")[2]))
    if not u or not db.hw_visible(hw, u):
        await cb.answer("Это задание уже недоступно.", show_alert=True)
        return
    await cb.answer()
    text, kb = hw_card(hw, db.hw_get_status(con, hw["id"], u["id"]), u)
    await edit(cb, text, kb)


@router.callback_query(F.data.startswith("hw:start:"))
async def hw_start(cb: CallbackQuery, state: FSMContext):
    u, hw = player(cb.from_user.id), db.get_homework(con, int(cb.data.split(":")[2]))
    if not u or not db.hw_visible(hw, u) or hw["kind"] != "quiz":
        await cb.answer("Это задание уже недоступно.", show_alert=True)
        return
    st = db.hw_get_status(con, hw["id"], u["id"])
    if st and st["status"] == "done":
        await cb.answer("Это задание ты уже выполнил(а) ✅", show_alert=True)
        return
    d = await state.get_data()
    if fresh(d) and d["pos"] < len(d["qids"]) and d.get("hw_id") != hw["id"]:
        await cb.answer("Сначала закончи текущий квиз (кнопка «🎯 Квиз»), потом возвращайся к домашке.",
                        show_alert=True)
        return
    remaining = db.hw_remaining(con, hw["id"], u["id"])
    if not remaining:
        await cb.answer("Ты уже ответил(а) на все вопросы этого задания.", show_alert=True)
        return
    await cb.answer()
    await drop_card(cb.bot, cb.message.chat.id, d)
    try:
        await cb.message.delete()   # карточка задания заменяется карточкой квиза
    except Exception:
        pass
    ch = db.get_character(con, u["id"])
    ctx = "homework_late" if is_overdue(hw["due_date"]) else "homework"
    await state.set_state(None)
    await state.set_data({"qids": remaining, "pos": 0, "correct": 0, "xp": 0, "coins": 0, "context": ctx,
                          "lvl0": ch["level"], "shown_at": time.time(), "day": today().isoformat(),
                          "hw_id": hw["id"], "card_id": None, "phase": "q"})
    if not st:
        db.hw_set_status(con, hw["id"], u["id"], "in_progress")
    db.log_event(con, u["id"], "hw_start", today(), context=ctx, extra=json.dumps({"hw_id": hw["id"]}))
    note = ("<i>⏰ Дедлайн уже прошёл: задание можно выполнить, но XP будет меньше.</i>\n\n"
            if ctx == "homework_late" else "")
    await send_question(cb.bot, cb.message.chat.id, state, note=note, new=True)


@router.callback_query(F.data.startswith("hw:submit:"))
async def hw_submit_start(cb: CallbackQuery, state: FSMContext):
    u, hw = player(cb.from_user.id), db.get_homework(con, int(cb.data.split(":")[2]))
    if not u or not db.hw_visible(hw, u) or hw["kind"] != "manual":
        await cb.answer("Это задание уже недоступно.", show_alert=True)
        return
    st = db.hw_get_status(con, hw["id"], u["id"])
    if st and st["status"] == "done":
        await cb.answer("Это задание уже принято ✅", show_alert=True)
        return
    await cb.answer()
    await state.set_state(Submit.waiting)
    await state.update_data(sub_hw=hw["id"], sub_card=cb.message.message_id)
    await edit(cb, f"📝 <b>{esc(hw['title'])}</b>\n\nОтправь свою работу <b>одним сообщением</b>: "
                   "текст, голосовое, фото или файл.", ikb([("❌ Отмена", f"hw:open:{hw['id']}")]))


@router.message(Submit.waiting, lambda m: not (m.text and m.text.startswith("/")))
async def hw_submit(m: Message, state: FSMContext, bot: Bot):
    d = await state.get_data()
    u, hw = player(m.from_user.id), db.get_homework(con, d.get("sub_hw") or 0)
    await state.set_state(None)
    if not u or not db.hw_visible(hw, u):
        await m.answer("Это задание уже недоступно.")
        return
    db.hw_set_status(con, hw["id"], u["id"], "submitted", submitted_at=db.utc_now(), teacher_comment=None,
                     sub_chat=m.chat.id, sub_msg=m.message_id)
    db.log_event(con, u["id"], "hw_submit", today(), extra=json.dumps({"hw_id": hw["id"]}))
    grp = db.group_name(con, u["group_id"])
    kb = ikb([("✅ Принять", f"hwr:acc:{hw['id']}:{u['id']}"), ("🔁 Доработать", f"hwr:rew:{hw['id']}:{u['id']}")])
    sent = 0
    for tid in TEACHERS:
        try:
            await bot.send_message(tid, f"📥 <b>Сдано:</b> {esc(hw['title'])} (#{hw['id']})\n"
                                        f"От: <b>{esc(u['nickname'])}</b>" + (f" [{esc(grp)}]" if grp else "")
                                        + ("\n⚠️ после дедлайна" if is_overdue(hw["due_date"]) else ""))
            await bot.copy_message(tid, m.chat.id, m.message_id, reply_markup=kb)
            sent += 1
        except Exception:
            logging.warning("Не удалось доставить работу учителю %s", tid)
    result = (f"📝 <b>{esc(hw['title'])}</b>\n\n✅ Отправлено учителю! Статус: на проверке." if sent else
              f"📝 <b>{esc(hw['title'])}</b>\n\nРабота сохранена, но доставить её учителю сейчас не получилось. "
              "Напиши ему лично.")
    try:
        await bot.edit_message_text(result, chat_id=m.chat.id, message_id=d["sub_card"],
                                    reply_markup=ikb([("⬅️ К списку", "hw:list")]))
    except Exception:
        await m.answer(result)


# ======================= учитель: кнопочный интерфейс =======================
# Нижнее меню: Ученики · Группы · Задания · Награды · Сводка. Внутри всё правится на месте, без команд.
PAGE = 8
GROUP_NAME_RE = re.compile(r"[\w\- ]{1,30}")   # буквы, цифры, пробелы, _ и -
CONTENT_HELP = ("📚 <b>Загрузка вопросов и памяток</b>\n\nПришлите боту файл .xlsx (скрепка → «Файл») прямо в этот чат. "
                "В нём листы <b>questions</b> (вопросы) и <b>cheatsheets</b> (памятки). Бот ответит, сколько загружено "
                "и какие строки пропущены. Вопросы с тем же id обновляются, новые добавляются. "
                "Чтобы убрать вопрос, поставьте в колонке active значение 0.")


def nav_row(page, pages, prefix):
    """Строка «◀ 2/3 ▶» для длинных списков."""
    if pages <= 1:
        return []
    row = []
    if page > 0:
        row.append(("◀", f"{prefix}:{page - 1}"))
    row.append((f"{page + 1}/{pages}", "noop"))
    if page < pages - 1:
        row.append(("▶", f"{prefix}:{page + 1}"))
    return [row]


async def edit_prompt(bot: Bot, chat_id, state: FSMContext, text, kb=None):
    """Правит «вопросное» сообщение мастера (после того, как учитель ввёл текст)."""
    d = await state.get_data()
    pid = d.get("prompt_id")
    if pid:
        try:
            await bot.edit_message_text(text, chat_id=chat_id, message_id=pid, reply_markup=kb)
            return
        except TelegramBadRequest as e:
            if "not modified" in str(e).lower():
                return
    msg = await bot.send_message(chat_id, text, reply_markup=kb)
    await state.update_data(prompt_id=msg.message_id)


def user_by_id(uid):
    return con.execute("SELECT * FROM users WHERE id=?", (uid,)).fetchone()


def group_by_id(gid):
    return con.execute("SELECT * FROM groups WHERE id=?", (gid,)).fetchone()


@teacher.callback_query(F.data == "noop")
async def noop(cb: CallbackQuery):
    await cb.answer()


# ---------- нижнее меню учителя ----------
async def teacher_screen(m: Message, state: FSMContext, text, kb):
    """Любая кнопка нижнего меню обрывает незаконченный мастер и открывает свой экран."""
    await state.clear()
    await tidy(m)
    await m.answer(text, reply_markup=kb)


@teacher.message(Command("profile"))
@teacher.message(Command("quiz"))
@teacher.message(Command("memo"))
@teacher.message(F.text.in_({BTN_PANEL, BTN_PROFILE, BTN_QUIZ, BTN_MEMO}))
async def t_panel(m: Message, state: FSMContext):
    text, kb = panel_content()
    await teacher_screen(m, state, text, kb)


@teacher.message(CommandStart())
async def t_start(m: Message, state: FSMContext):
    await state.clear()
    u = player(m.from_user.id)
    if not u:
        uid = db.create_user(con, m.from_user.id, "Teacher", "teacher")
        db.log_event(con, uid, "register", today())
    elif u["role"] != "teacher":   # раньше зарегистрировались как ученик (TEACHER_IDS не был задан)
        db.make_teacher(con, u["id"])
    try:
        await m.bot.set_my_commands(TEACHER_COMMANDS, scope=BotCommandScopeChat(chat_id=m.chat.id))
    except Exception:
        pass
    await m.answer("👋 Вы вошли как <b>учитель</b>. Всё управление — кнопками внизу.", reply_markup=MENU_TEACHER)
    text, kb = panel_content()
    await m.answer(text, reply_markup=kb)


@teacher.message(Command("admin"))
@teacher.message(Command("help"))
async def t_help(m: Message, state: FSMContext):
    await teacher_screen(m, state, TEACHER_HELP, None)


@teacher.message(F.text == BTN_STUDENTS)
async def t_students(m: Message, state: FSMContext):
    text, kb = students_hub_content("c")
    await teacher_screen(m, state, text, kb)


@teacher.message(Command("groups"))
@teacher.message(F.text == BTN_GROUPS)
async def t_groups(m: Message, state: FSMContext):
    text, kb = groups_list_content()
    await teacher_screen(m, state, text, kb)


@teacher.message(F.text == BTN_REWARDS)
async def t_rewards(m: Message, state: FSMContext):
    text, kb = rewards_main_content()
    await teacher_screen(m, state, text, kb)


@teacher.message(Command("hw"))
@teacher.message(F.text.in_({BTN_TASKS, BTN_HW}))
async def t_tasks(m: Message, state: FSMContext):
    text, kb = teacher_hw_content()
    await teacher_screen(m, state, text, kb)


# ---------- сводка ----------
def panel_content():
    s = db.teacher_overview(con, today())
    flags = an.risk_flags(con, today())
    text = teacher_panel().rstrip()
    if s["students"]:
        text += "\n" + an.status_line(an.student_status(con, today()))
    text += "\n\nВсё управление — кнопками внизу. Команды с «/» тоже работают."
    tips = []
    if s["groups"] == 0:
        tips.append("1️⃣ Создайте группу: «🏷 Группы» → «➕ Создать группу».")
    if s["students"] == 0:
        tips.append("2️⃣ Попросите учеников написать боту /start: они появятся в «👥 Ученики».")
    elif s["groups"]:
        tips.append("Новых учеников без группы смотрите в «👥 Ученики» → «Без группы».")
    if tips:
        text += "\n\n<b>Подсказки</b>\n" + "\n".join(tips)
    rows = []
    if s["pending"]:
        rows.append([(f"📥 На проверке ({s['pending']})", "rv:list")])
    if flags:
        rows.append([(f"⚠️ Кому нужно внимание ({len(flags)})", "tp:flags")])
    rows.append([("📬 Дайджест сейчас", "tp:digest"), ("🧩 Типичные ошибки", "ms:a:0")])
    rows.append([("📤 Экспорт в Excel", "tp:export"), ("🔔 Автоматика", "tp:auto")])
    rows.append([("💾 Копия базы", "tp:backup"), ("⌨️ Команды", "tp:cmds")])
    rows.append([("📚 Загрузка вопросов", "tp:content")])
    return text, ikb(*rows)


def flags_content():
    flags = an.risk_flags(con, today())
    back = [("⬅️ Назад", "tp:home")]
    if not flags:
        return "✅ <b>Сигналов нет.</b> Все ученики занимаются в обычном режиме.", ikb(back)
    names = {r["id"]: r["nickname"] for r in con.execute("SELECT id, nickname FROM users")}
    lines = ["⚠️ <b>Кому нужно внимание</b>", ""]
    lines += [f"• <b>{esc(names[uid])}</b> — {esc(an.flags_text(fl))}" for uid, fl in flags.items()]
    lines.append("\nНажмите на ученика, чтобы открыть карточку, наградить или написать ему.")
    return "\n".join(lines), ikb(*[[(names[uid], f"st:c:{uid}:all.0")] for uid in list(flags)[:25]], back)


def auto_content():
    def state(key):
        return "✅ включены" if db.get_setting(con, key, "1") == "1" else "🔕 выключены"
    off = con.execute("SELECT COUNT(*) FROM users WHERE role='student' AND is_active=1 AND remind=0").fetchone()[0]
    text = ("🔔 <b>Автоматика</b>\n\n"
            f"• <b>Напоминания ученикам:</b> {state('reminders')}. Каждый день в {SCHED.remind_hour}:00: о квизе "
            "(тем, кто занимался в последние 3 дня, и тем, у кого есть серия) и о дедлайнах сегодня и завтра. "
            "Если ученик 3 раза не ответил на напоминание, бот перестаёт напоминать, пока он не вернётся.\n"
            f"• <b>Недельный дайджест вам:</b> {state('digest')}. По {WEEKDAYS[SCHED.digest_weekday]} в "
            f"{SCHED.digest_hour}:00.\n"
            f"• <b>Сигналы о проблемах:</b> {state('flags')}. Ежедневно в {SCHED.digest_hour}:00, только новые.\n\n"
            f"Ученики, отключившие напоминания: {off}. Время меняется переменными REMIND_HOUR, DIGEST_WEEKDAY, "
            "DIGEST_HOUR (см. DEPLOY.md).")
    rows = [[(("🔕 Выключить" if db.get_setting(con, k, "1") == "1" else "🔔 Включить") + f" {name}", f"au:t:{k}")]
            for k, name in (("reminders", "напоминания"), ("digest", "дайджест"), ("flags", "сигналы"))]
    return text, ikb(*rows, [("⬅️ Назад", "tp:home")])


@teacher.callback_query(F.data.startswith("au:t:"))
async def auto_toggle(cb: CallbackQuery):
    key = cb.data.split(":")[2]
    if key in ("reminders", "digest", "flags"):
        db.set_setting(con, key, "0" if db.get_setting(con, key, "1") == "1" else "1")
    await cb.answer("Сохранено")
    text, kb = auto_content()
    await edit(cb, text, kb)


async def send_digest_now(bot: Bot, chat_id):
    for i, chunk in enumerate(an.split_text(an.build_digest(con, today()))):
        await bot.send_message(chat_id, chunk)


async def send_export(bot: Bot, chat_id):
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, f"quest_bot_{today().isoformat()}.xlsx")
        an.build_export(con, today(), path)
        await bot.send_document(chat_id, FSInputFile(path), caption=(
            "📤 Excel-файл: листы «Ученики», «Темы × ученики», «Динамика», «Журнал ответов» (все ответы за полгода) "
            "и «Домашка». Откроется в Excel и в Google Таблицах (Файл → Импорт)."))


@teacher.message(Command("digest"))
async def t_digest(m: Message):
    await send_digest_now(m.bot, m.chat.id)


@teacher.message(Command("export"))
async def t_export(m: Message):
    await send_export(m.bot, m.chat.id)


@teacher.message(Command("flags"))
async def t_flags(m: Message):
    text, kb = flags_content()
    await m.answer(text, reply_markup=kb)


async def send_backup(bot: Bot, chat_id):
    """Присылает учителю копию базы (ученики, прогресс, журнал ответов) файлом в Telegram."""
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, f"quest_bot_backup_{today().isoformat()}.db")
        dst = sqlite3.connect(path)
        con.backup(dst)          # безопасная копия работающей базы
        dst.close()
        await bot.send_document(chat_id, FSInputFile(path), caption=(
            "💾 Резервная копия базы: все ученики, прогресс и журнал ответов. Сохраните файл в надёжном месте "
            "(например, в «Избранном» Telegram или на компьютере). Делайте копию раз в неделю и перед обновлением бота."))


@teacher.message(Command("backup"))
async def t_backup(m: Message):
    await send_backup(m.bot, m.chat.id)


@teacher.callback_query(F.data.startswith("tp:"))
async def panel_nav(cb: CallbackQuery):
    act = cb.data.split(":")[1]
    if act == "backup":
        await cb.answer("Отправляю файл…")
        await send_backup(cb.bot, cb.message.chat.id)
        return
    if act == "digest":
        await cb.answer("Формирую дайджест…")
        await send_digest_now(cb.bot, cb.message.chat.id)
        return
    if act == "export":
        await cb.answer("Собираю Excel…")
        await send_export(cb.bot, cb.message.chat.id)
        return
    await cb.answer()
    if act == "flags":
        text, kb = flags_content()
        await edit(cb, text, kb)
    elif act == "auto":
        text, kb = auto_content()
        await edit(cb, text, kb)
    elif act == "cmds":
        await edit(cb, TEACHER_HELP, ikb([("⬅️ Назад", "tp:home")]))
    elif act == "content":
        await edit(cb, CONTENT_HELP, ikb([("⬅️ Назад", "tp:home")]))
    else:
        text, kb = panel_content()
        await edit(cb, text, kb)


# ---------- ученики ----------
def filter_label(flt):
    if flt == "all":
        return "Все"
    if flt == "none":
        return "Без группы"
    return db.group_name(con, int(flt[1:])) or "Группа"


def filtered_students(flt):
    since = (today() - timedelta(days=6)).isoformat()
    rows = db.students_overview(con, since, int(flt[1:]) if flt.startswith("g") else None)
    return [r for r in rows if r["group_id"] is None] if flt == "none" else rows


def students_hub_content(mode):
    """Выбор, откуда показывать учеников. mode: c — карточки, r — выбор для награды."""
    allst = db.students_in_scope(con)
    if not allst:
        return ("Учеников пока нет. Они появятся, когда напишут боту /start и придумают никнейм.", None)
    groups = db.groups_overview(con)
    if not groups:
        return students_list_content(mode, "all", 0)
    none_n = sum(1 for u in allst if u["group_id"] is None)
    title = "👥 <b>Ученики.</b> Кого показать?" if mode == "c" else "🎁 <b>Кого наградить?</b> Откуда взять ученика:"
    rows = [[(f"📋 Все ({len(allst)})", f"st:l:{mode}:all:0")]]
    if none_n:
        rows.append([(f"🆓 Без группы ({none_n})", f"st:l:{mode}:none:0")])
    rows += [[(f"🏷 {g['name']} ({g['members']})", f"st:l:{mode}:g{g['id']}:0")] for g in groups]
    return title, ikb(*rows)


def students_list_content(mode, flt, page):
    rows_ = filtered_students(flt)
    head = ("👥 <b>Ученики</b>" if mode == "c" else "🎁 <b>Кого наградить?</b>") + f" · {esc(filter_label(flt))}"
    back = [[("🔎 Другой фильтр", f"st:f:{mode}")]] if db.groups_overview(con) else []
    if not rows_:
        return head + "\n\nЗдесь пока никого.", (ikb(*back) if back else None)
    pages = max(1, -(-len(rows_) // PAGE))
    page = max(0, min(page, pages - 1))
    kb = []
    status = an.student_status(con, today())
    for r in rows_[page * PAGE:(page + 1) * PAGE]:
        tag = f" [{r['grp']}]" if flt == "all" and r["grp"] else ""
        cb = f"st:c:{r['id']}:{flt}.{page}" if mode == "c" else f"rw:u:{r['id']}"
        kb.append([(f"{status[r['id']]['icon']} {r['nickname']}{tag} · ур. {r['level']}", cb)])
    kb += nav_row(page, pages, f"st:l:{mode}:{flt}")
    kb += back
    return f"{head} ({len(rows_)})\n{an.LEGEND}", ikb(*kb)


def student_card_content(uid, back):
    u = user_by_id(uid)
    rows = db.students_overview(con, (today() - timedelta(days=6)).isoformat(), None, uid)
    if not u or not rows:
        return "Ученик не найден.", None
    r, ch = rows[0], db.get_character(con, uid)
    flt, page = back.split(".")
    acc = f"{round(100 * r['ok'] / r['n'])}%" if r["n"] else "—"
    daily = {"done": "✅ пройден", "started": "⏳ начат", "none": "не начат"}[db.daily_status(con, uid, today())]
    text = "\n".join([
        f"👤 <b>{esc(u['nickname'])}</b>" + (f" · группа {esc(r['grp'])}" if r["grp"] else " · без группы"),
        f"⭐ Уровень {ch['level']} ({db.cefr_for_level(ch['level'])}) · XP {ch['xp']} · 🪙 {ch['coins']}",
        f"🔥 Серия: {db.effective_streak(ch, today())} дн. · ❄️ заморозок: {ch['freezes']}",
        f"📅 Квиз дня: {daily}",
        f"Последний ответ: {r['last_answer'] or 'никогда'} · за 7 дней: ответов {r['n']}, верно {acc}"])
    stt = an.student_status(con, today(), user_id=uid)[uid]
    text += f"\n🚦 {stt['icon']} {esc(stt['reason'])}"
    return text, ikb([("📈 Отчёт", f"st:r:{uid}:{back}"), ("🗺 Карта тем", f"mp:s:{uid}:{back}:0")],
                     [("🧩 Ошибки ученика", f"ms:u{uid}:0"), ("🏷 Группа", f"st:g:{uid}:{back}")],
                     [("🎁 Наградить", f"rw:a:u{uid}:p"), ("⚠️ Штраф", f"rw:a:u{uid}:m")],
                     [("⬅️ К списку", f"st:l:c:{flt}:{page}")])


@teacher.callback_query(F.data.startswith("st:"))
async def students_nav(cb: CallbackQuery):
    p = cb.data.split(":")
    act, toast = p[1], None
    if act == "f":
        text, kb = students_hub_content(p[2])
    elif act == "l":
        text, kb = students_list_content(p[2], p[3], int(p[4]))
    elif act == "c":
        text, kb = student_card_content(int(p[2]), p[3])
    elif act == "r":
        u = user_by_id(int(p[2]))
        text = student_report_text(u) if u else "Ученик не найден."
        kb = ikb([("⬅️ К карточке", f"st:c:{p[2]}:{p[3]}")])
        if len(text) > 3900:
            await cb.answer()
            await send_long(cb.message, text, reply_markup=kb)
            return
    elif act == "g":
        u = user_by_id(int(p[2]))
        text = f"🏷 <b>Группа для {esc(u['nickname'])}</b>\nСейчас: {esc(db.group_name(con, u['group_id']) or 'без группы')}. " \
               "Ученик может быть только в одной группе: при переводе он уйдёт из прежней."
        rows = [[(("✔️ " if g["id"] == u["group_id"] else "") + g["name"], f"st:s:{u['id']}:{g['id']}:{p[3]}")]
                for g in db.groups_overview(con)]
        rows.append([(("✔️ " if u["group_id"] is None else "") + "🆓 Без группы", f"st:s:{u['id']}:0:{p[3]}")])
        rows.append([("⬅️ Назад", f"st:c:{u['id']}:{p[3]}")])
        kb = ikb(*rows)
    else:  # s — назначить группу
        u = user_by_id(int(p[2]))
        gid = int(p[3]) or None
        db.set_group(con, u["id"], gid)
        toast = f"✅ {u['nickname']} → {db.group_name(con, gid) or 'без группы'}"
        text, kb = student_card_content(u["id"], p[4])
    await cb.answer(toast)
    await edit(cb, text, kb)


# ---------- карта освоения тем и типичные ошибки ----------
MAP_PAGE = 10


def student_map_content(uid, page, back):
    u = user_by_id(uid)
    items = an.student_map(con, uid)
    flt, bpage = back.split(".")
    back_kb = [("⬅️ К карточке", f"st:c:{uid}:{back}")]
    if not u or not items:
        return f"🗺 <b>Карта тем · {esc(u['nickname']) if u else '?'}</b>\n\nОтветов по темам пока нет.", ikb(back_kb)
    cnt = Counter(x["state"] for x in items)
    pages = max(1, -(-len(items) // MAP_PAGE))
    page = max(0, min(page, pages - 1))
    lines = [f"🗺 <b>Карта тем · {esc(u['nickname'])}</b>",
             f"🔴 проблемы: {cnt['problem']} · 🟡 в процессе: {cnt['progress']} · 🟢 освоено: {cnt['mastered']}",
             "<i>Состояние темы считается по последним 10 ответам. Сверху самые проблемные.</i>", ""]
    for x in items[page * MAP_PAGE:(page + 1) * MAP_PAGE]:
        lines.append(f"{an.MASTERY_ICON[x['state']]} {esc(x['topic'][:50])} — {x['acc']}% ({x['ok']}/{x['n']}), "
                     f"всего ответов {x['total']}")
    return "\n".join(lines), ikb(*nav_row(page, pages, f"mp:s:{uid}:{back}"), back_kb)


def group_map_content(gid, page):
    g = group_by_id(gid)
    if not g:
        return "Группа не найдена.", None
    rows = an.group_map(con, gid)
    back_kb = [("⬅️ К группе", f"gr:c:{gid}")]
    if not rows:
        return f"🗺 <b>Карта группы · {esc(g['name'])}</b>\n\nОтветов по темам пока нет.", ikb(back_kb)
    pages = max(1, -(-len(rows) // MAP_PAGE))
    page = max(0, min(page, pages - 1))
    lines = [f"🗺 <b>Карта группы · {esc(g['name'])}</b>",
             f"Тем с ответами: {len(rows)}. Сверху те, где больше всего проблем.",
             "<i>🔴 проблема · 🟡 в процессе · 🟢 освоено: сколько учеников в каждом состоянии</i>", ""]
    for r in rows[page * MAP_PAGE:(page + 1) * MAP_PAGE]:
        who = f" — {esc(', '.join(r['problem_names'][:3]))}" + ("…" if len(r["problem_names"]) > 3 else "") \
            if r["problem"] else ""
        lines.append(f"{esc(r['topic'][:45])}: 🔴{r['problem']} 🟡{r['progress']} 🟢{r['mastered']}{who}")
    return "\n".join(lines), ikb(*nav_row(page, pages, f"mp:g:{gid}"), back_kb)


MIST_PAGE = 5


def mistakes_content(scope, page):
    """scope: a — все ученики, g<id> — группа, u<id> — ученик."""
    kind, ident = scope[0], (int(scope[1:]) if len(scope) > 1 else None)
    since = today() - timedelta(days=13)
    if kind == "g":
        items, label, back = an.common_mistakes(con, since, group_id=ident, limit=50), \
            f"группа {esc((group_by_id(ident) or {'name': '?'})['name'])}", f"gr:c:{ident}"
    elif kind == "u":
        u = user_by_id(ident)
        items, label, back = an.common_mistakes(con, since, user_id=ident, limit=50, min_wrong=2), \
            f"{esc(u['nickname']) if u else '?'}", f"st:c:{ident}:all.0"
    else:
        items, label, back = an.common_mistakes(con, since, limit=50), "все ученики", "tp:home"
    back_kb = [("⬅️ Назад", back)]
    head = f"🧩 <b>Типичные ошибки · {label}</b> (14 дней)"
    if not items:
        return head + "\n\nПока нет вопросов, на которых ошиблись " + ("2+" if kind == "u" else "3+") + " раза.", ikb(back_kb)
    pages = max(1, -(-len(items) // MIST_PAGE))
    page = max(0, min(page, pages - 1))
    chunk = items[page * MIST_PAGE:(page + 1) * MIST_PAGE]
    text = f"{head}\n<i>Вопросы с наибольшим числом ошибок и самый частый неверный ответ.</i>\n\n" \
           + an.mistakes_text(chunk, start=page * MIST_PAGE + 1)
    return text, ikb(*nav_row(page, pages, f"ms:{scope}"), back_kb)


@teacher.callback_query(F.data.startswith("mp:"))
async def map_nav(cb: CallbackQuery):
    p = cb.data.split(":")
    await cb.answer()
    if p[1] == "s":      # mp:s:<uid>:<back>:<page>
        text, kb = student_map_content(int(p[2]), int(p[4]), p[3])
    else:                # mp:g:<gid>:<page>
        text, kb = group_map_content(int(p[2]), int(p[3]))
    await edit(cb, text, kb)


@teacher.callback_query(F.data.startswith("ms:"))
async def mistakes_nav(cb: CallbackQuery):
    p = cb.data.split(":")
    await cb.answer()
    text, kb = mistakes_content(p[1], int(p[2]))
    await edit(cb, text, kb)


@teacher.message(Command("mistakes"))
async def t_mistakes(m: Message):
    text, kb = mistakes_content("a", 0)
    await m.answer(text, reply_markup=kb)


# ---------- группы ----------
def groups_list_content():
    gs = db.groups_overview(con)
    rows = [[(f"🏷 {g['name']}" + (f" · {g['target_cefr']}" if g["target_cefr"] else "") + f" · {g['members']} уч.",
              f"gr:c:{g['id']}")] for g in gs]
    rows.append([("➕ Создать группу", "gr:new")])
    none_n = sum(1 for u in db.students_in_scope(con) if u["group_id"] is None)
    if none_n:
        rows.append([(f"🆓 Ученики без группы ({none_n})", "st:l:c:none:0")])
    return ("🏷 <b>Группы</b>" if gs else "🏷 <b>Групп пока нет.</b> Создайте первую:"), ikb(*rows)


def group_card_content(gid, note=""):
    g = group_by_id(gid)
    if not g:
        return "Группа не найдена.", None
    members = db.group_students(con, gid)
    status = an.student_status(con, today())
    names = ", ".join(f"{status[u['id']]['icon']}{esc(u['nickname'])}" for u in members[:20]) \
        + ("…" if len(members) > 20 else "")
    text = (f"{note}🏷 <b>{esc(g['name'])}</b>" + (f" · цель {g['target_cefr']}" if g["target_cefr"] else "")
            + f"\nУчеников: {len(members)}" + (f"\n{names}" if members else ""))
    return text, ikb(
        [("👥 Состав", f"st:l:c:g{gid}:0"), ("📈 Отчёт", f"gr:rep:{gid}")],
        [("🗺 Карта группы", f"mp:g:{gid}:0"), ("🧩 Типичные ошибки", f"ms:g{gid}:0")],
        [("➕ Добавить учеников", f"gr:addn:{gid}"), ("🎁 Наградить группу", f"rw:a:g{gid}:p")],
        [("📝 Задание группе", f"nhw:preg:{gid}"), ("🎯 Уровень", f"gr:lvl:{gid}")],
        [("✏️ Название", f"gr:ren:{gid}"), ("🗑 Удалить", f"gr:del:{gid}")],
        [("⬅️ К группам", "gr:l")])


def picker_content(gid, page, selected):
    g = group_by_id(gid)
    cands = db.students_for_picker(con, gid)
    if not cands:
        return None, None
    pages = max(1, -(-len(cands) // PAGE))
    page = max(0, min(page, pages - 1))
    rows = [[(f"{'✅' if r['id'] in selected else '☐'} {r['nickname']} · {r['grp'] or 'без группы'}",
              f"gr:t:{gid}:{r['id']}:{page}")] for r in cands[page * PAGE:(page + 1) * PAGE]]
    rows += nav_row(page, pages, f"gr:add:{gid}")
    rows.append([(f"✅ Добавить выбранных ({len(selected)})", f"gr:ok:{gid}")])
    rows.append([("⬅️ Отмена", f"gr:c:{gid}")])
    text = (f"➕ <b>Добавить в «{esc(g['name'])}»</b>\nОтметьте учеников (сначала идут те, у кого нет группы). "
            "Ученик может быть только в одной группе: при добавлении он уйдёт из прежней.")
    return text, ikb(*rows)


@teacher.callback_query(F.data.startswith("gr:"))
async def groups_nav(cb: CallbackQuery, state: FSMContext):
    p = cb.data.split(":")
    act, toast = p[1], None
    if act in ("l", "c"):
        await state.clear()          # выход из ввода названия
    if act == "l":
        text, kb = groups_list_content()
    elif act == "c":
        text, kb = group_card_content(int(p[2]))
    elif act == "rep":
        g = group_by_id(int(p[2]))
        text = group_report_text(g) if g else "Группа не найдена."
        kb = ikb([("⬅️ К группе", f"gr:c:{p[2]}")])
        if len(text) > 3900:
            await cb.answer()
            await send_long(cb.message, text, reply_markup=kb)
            return
    elif act == "new":
        await state.clear()
        await state.set_state(NewGroup.name)
        await state.update_data(prompt_id=cb.message.message_id)
        text = "Напишите <b>название</b> группы (до 30 символов; можно с пробелами, например «A2 вторник»)."
        kb = ikb([("❌ Отмена", "gr:l")])
    elif act == "ren":
        await state.clear()
        await state.set_state(NewGroup.name)
        await state.update_data(prompt_id=cb.message.message_id, rename_gid=int(p[2]))
        text = "Напишите <b>новое название</b> группы."
        kb = ikb([("❌ Отмена", f"gr:c:{p[2]}")])
    elif act == "lvl":
        text = "🎯 <b>Целевой уровень группы</b> (для информации):"
        kb = ikb([(c, f"gr:setl:{p[2]}:{c}") for c in db.CEFR], [("Не указывать", f"gr:setl:{p[2]}:-")],
                 [("⬅️ Назад", f"gr:c:{p[2]}")])
    elif act == "setl":
        db.set_group_level(con, int(p[2]), None if p[3] == "-" else p[3])
        toast = "✅ Уровень сохранён"
        text, kb = group_card_content(int(p[2]))
    elif act == "addn":   # вход в выбор учеников: сбрасываем выбор
        await state.update_data(sel=[])
        text, kb = picker_content(int(p[2]), 0, set())
        if not text:
            await cb.answer("Все ученики уже в этой группе или учеников ещё нет.", show_alert=True)
            return
    elif act in ("add", "t"):
        gid = int(p[2])
        d = await state.get_data()
        sel = set(d.get("sel", []))
        page = int(p[4]) if act == "t" else int(p[3])
        if act == "t":
            sel ^= {int(p[3])}
            await state.update_data(sel=sorted(sel))
        text, kb = picker_content(gid, page, sel)
    elif act == "ok":
        gid = int(p[2])
        sel = (await state.get_data()).get("sel", [])
        if not sel:
            await cb.answer("Никого не выбрано: отметьте учеников галочками.", show_alert=True)
            return
        for uid in sel:
            db.set_group(con, uid, gid)
        await state.update_data(sel=[])
        toast = f"✅ Добавлено: {len(sel)}"
        text, kb = group_card_content(gid, note=f"✅ Добавлено учеников: {len(sel)}\n\n")
    elif act == "del":
        gid = int(p[2])
        if db.group_students(con, gid):
            await cb.answer("В группе есть ученики. Сначала переведите их в другую группу.", show_alert=True)
            return
        text = f"🗑 Удалить группу «{esc(group_by_id(gid)['name'])}»?"
        kb = ikb([("✅ Да, удалить", f"gr:delok:{gid}"), ("❌ Нет", f"gr:c:{gid}")])
    else:  # delok
        db.delete_group(con, int(p[2]))
        toast = "Группа удалена"
        text, kb = groups_list_content()
    await cb.answer(toast)
    await edit(cb, text, kb)


@teacher.message(NewGroup.name, F.text, ~F.text.startswith("/"))
async def group_name_input(m: Message, state: FSMContext):
    name = " ".join(m.text.split())
    d = await state.get_data()
    await tidy(m)
    cancel = ikb([("❌ Отмена", f"gr:c:{d['rename_gid']}" if d.get("rename_gid") else "gr:l")])
    if not GROUP_NAME_RE.fullmatch(name):
        await edit_prompt(m.bot, m.chat.id, state, "Название: до 30 символов, буквы, цифры, пробелы, _ и -. "
                          "Попробуйте ещё раз.", cancel)
        return
    existing = db.get_group(con, name)
    if existing and existing["id"] != d.get("rename_gid"):
        await edit_prompt(m.bot, m.chat.id, state, "Группа с таким названием уже есть. Придумайте другое.", cancel)
        return
    if d.get("rename_gid"):
        gid = d["rename_gid"]
        db.rename_group(con, gid, name)
        note = "✅ Название изменено.\n\n"
    else:
        gid = db.create_group(con, name, None)
        note = "✅ Группа создана. Добавьте в неё учеников или выберите уровень.\n\n"
    text, kb = group_card_content(gid, note=note)
    await edit_prompt(m.bot, m.chat.id, state, text, kb)
    await state.clear()


# ---------- награды и штрафы ----------
KIND_BTN = {"xp": ("⭐ XP", (10, 20, 50, 100)), "coins": ("🪙 Монеты", (1, 3, 5, 10)),
            "freeze": ("❄️ Заморозка серии", (1,))}
REASONS = {"p": ["За активность на уроке", "За хорошую домашку", "За прогресс", "Просто молодец"],
           "m": ["Не сделана домашка", "Пропуск без предупреждения", "Нарушение дисциплины"]}


def tgt_info(tgt):
    """(подпись, куда вернуться) для цели 'u<id>' (ученик) или 'g<id>' (группа)."""
    i = int(tgt[1:])
    if tgt[0] == "u":
        u = user_by_id(i)
        return (f"👤 {esc(u['nickname'])}" if u else "👤 ?"), f"st:c:{i}:all.0"
    g = group_by_id(i)
    return (f"🏷 {esc(g['name'])} (вся группа)" if g else "🏷 ?"), f"gr:c:{i}"


def rewards_main_content():
    return "🎁 <b>Награды и штрафы.</b> Кому?", ikb([("👤 Ученику", "st:f:r")], [("🏷 Всей группе", "rw:gl")])


def reasons_content(tgt, sign, kind, amount):
    label, _ = tgt_info(tgt)
    amt = f"{'+' if sign == 'p' else '−'}{amount} {KIND_BTN[kind][0]}"
    rows = [[(r, f"rw:r:{tgt}:{sign}:{kind}:{amount}:{i}")] for i, r in enumerate(REASONS[sign])]
    rows.append([("Без причины", f"rw:r:{tgt}:{sign}:{kind}:{amount}:n")])
    rows.append([("✏️ Написать свою", f"rw:rc:{tgt}:{sign}:{kind}:{amount}")])
    rows.append([("⬅️ Назад", f"rw:k:{tgt}:{sign}:{kind}")])
    return f"{label}\n{'🎁 Награда' if sign == 'p' else '⚠️ Штраф'}: <b>{amt}</b>\nПричина? (её увидит ученик)", ikb(*rows)


async def do_adjust(bot: Bot, teacher_tg, tgt, sign, kind, amount, reason):
    signed = amount if sign == "p" else -amount
    mark = f"{'+' if sign == 'p' else '−'}{amount} {KIND_BTN[kind][0]}"
    note = f"\n💬 {esc(reason)}" if reason else ""
    if tgt[0] == "u":
        u = user_by_id(int(tgt[1:]))
        applied, notified = await apply_and_notify(bot, teacher_tg, u, kind, signed, reason)
        if applied == 0:
            return "Ничего не изменилось (достигнут предел или уже ноль)."
        return (f"✅ {esc(u['nickname'])}: <b>{mark}</b>{note}"
                + ("" if notified else "\n(Ученик не получил уведомление: он не писал боту или заблокировал его.)"))
    g = group_by_id(int(tgt[1:]))
    members = db.group_students(con, g["id"])
    done = sent = 0
    for u in members:
        applied, notified = await apply_and_notify(bot, teacher_tg, u, kind, signed, reason)
        done += applied != 0
        sent += notified
    return f"✅ Группа {esc(g['name'])}: <b>{mark}</b> — получили {done} из {len(members)}, уведомлены: {sent}.{note}"


@teacher.callback_query(F.data.startswith("rw:"))
async def rewards_nav(cb: CallbackQuery, state: FSMContext):
    p = cb.data.split(":")
    act = p[1]
    if act in ("m", "x", "gl", "u", "a", "k", "n"):
        await state.clear()            # выход из ввода числа или причины
    if act == "x":
        await cb.answer()
        await edit(cb, "Отменено.")
        return
    if act == "m":
        text, kb = rewards_main_content()
    elif act == "gl":
        gs = db.groups_overview(con)
        text = "🏷 Какой группе?" if gs else "Групп пока нет. Создайте: «🏷 Группы»."
        kb = ikb(*[[(f"{g['name']} ({g['members']})", f"rw:a:g{g['id']}:p")] for g in gs],
                 [("⬅️ Назад", "rw:m")])
    elif act == "u":
        label, back = tgt_info(f"u{p[2]}")
        text = f"{label}\nЧто сделать?"
        kb = ikb([("🎁 Наградить", f"rw:a:u{p[2]}:p"), ("⚠️ Штраф", f"rw:a:u{p[2]}:m")], [("❌ Отмена", "rw:x")])
    elif act == "a":
        tgt, sign = p[2], p[3]
        label, back = tgt_info(tgt)
        kinds = [k for k in KIND_BTN if not (sign == "m" and k == "xp")]
        text = (f"{label}\n{'🎁 Награда' if sign == 'p' else '⚠️ Штраф'}: что именно?"
                + ("\n(Опыт не списывается: уровень не должен падать.)" if sign == "m" else ""))
        kb = ikb(*[[(KIND_BTN[k][0], f"rw:k:{tgt}:{sign}:{k}")] for k in kinds], [("⬅️ Назад", back)])
    elif act == "k":
        tgt, sign, kind = p[2], p[3], p[4]
        label, _ = tgt_info(tgt)
        text = f"{label}\n{'🎁 Награда' if sign == 'p' else '⚠️ Штраф'}: {KIND_BTN[kind][0]}. Сколько?"
        kb = ikb([(str(n), f"rw:n:{tgt}:{sign}:{kind}:{n}") for n in KIND_BTN[kind][1]],
                 [("✏️ Другое число", f"rw:nc:{tgt}:{sign}:{kind}")], [("⬅️ Назад", f"rw:a:{tgt}:{sign}")])
    elif act == "n":
        text, kb = reasons_content(p[2], p[3], p[4], int(p[5]))
    elif act == "nc":
        await state.set_state(RW.amount)
        await state.update_data(tgt=p[2], sign=p[3], kind=p[4], prompt_id=cb.message.message_id)
        text = f"{tgt_info(p[2])[0]}\nНапишите число ({KIND_BTN[p[4]][0]}), от 1 до 9999."
        kb = ikb([("❌ Отмена", "rw:x")])
    elif act == "rc":
        await state.set_state(RW.reason)
        await state.update_data(tgt=p[2], sign=p[3], kind=p[4], amount=int(p[5]), prompt_id=cb.message.message_id)
        text = "Напишите причину одним сообщением (её увидит ученик)."
        kb = ikb([("❌ Отмена", "rw:x")])
    else:  # r — применить
        tgt, sign, kind, amount, ridx = p[2], p[3], p[4], int(p[5]), p[6]
        reason = "" if ridx == "n" else REASONS[sign][int(ridx)]
        await cb.answer()
        result = await do_adjust(cb.bot, cb.from_user.id, tgt, sign, kind, amount, reason)
        await edit(cb, result, ikb([("⬅️ Назад", tgt_info(tgt)[1])], [("🎁 Ещё", "rw:m")]))
        return
    await cb.answer()
    await edit(cb, text, kb)


@teacher.message(RW.amount, F.text, ~F.text.startswith("/"))
async def reward_amount_input(m: Message, state: FSMContext):
    d = await state.get_data()
    await tidy(m)
    if not m.text.strip().isdigit() or not 1 <= int(m.text.strip()) <= 9999:
        await edit_prompt(m.bot, m.chat.id, state, "Нужно целое число от 1 до 9999. Попробуйте ещё раз.",
                          ikb([("❌ Отмена", "rw:x")]))
        return
    await state.set_state(None)
    text, kb = reasons_content(d["tgt"], d["sign"], d["kind"], int(m.text.strip()))
    await edit_prompt(m.bot, m.chat.id, state, text, kb)


@teacher.message(RW.reason, F.text, ~F.text.startswith("/"))
async def reward_reason_input(m: Message, state: FSMContext):
    d = await state.get_data()
    await tidy(m)
    result = await do_adjust(m.bot, m.from_user.id, d["tgt"], d["sign"], d["kind"], d["amount"],
                             m.text.strip()[:100])
    await edit_prompt(m.bot, m.chat.id, state, result,
                      ikb([("⬅️ Назад", tgt_info(d["tgt"])[1])], [("🎁 Ещё", "rw:m")]))
    await state.clear()


# ======================= команды учителя (быстрые, дублируют кнопки) =======================
def rest_of(m: Message):
    """Всё, что написано после команды (название группы может содержать пробелы)."""
    parts = m.text.split(maxsplit=1)
    return " ".join(parts[1].split()) if len(parts) > 1 else ""


def capped(lines_, limit=10):
    """Длинные списки тем урезаем: остальное видно в «Карте тем» и в Excel."""
    if len(lines_) <= limit:
        return lines_
    return lines_[:limit] + [f"…и ещё {len(lines_) - limit} (полный список: «🗺 Карта тем» и Excel)"]


def student_report_text(u):
    ch = db.get_character(con, u["id"])
    since = (today() - timedelta(days=13)).isoformat()
    grp = db.group_name(con, u["group_id"])
    lines = [f"<b>{esc(u['nickname'])}</b>" + (f" · группа {esc(grp)}" if grp else "")
             + f" — ур. {ch['level']} ({db.cefr_for_level(ch['level'])}), XP {ch['xp']}, 🪙 {ch['coins']}, "
               f"серия {db.effective_streak(ch, today())}",
             f"Дней с активностью за 14 дней: {db.active_days(con, u['id'], since)}"]
    started, finished = db.quiz_counts(con, u["id"], since)
    lines.append(f"Квизы за 14 дней: начато {started}, закончено {finished}"
                 + (f" (незаконченные: {started - finished}, их ответы тоже учтены в статистике)"
                    if started > finished else ""))
    base = len(lines)
    for title, col in (("По темам (от слабых к сильным)", "topic"), ("По навыкам", "skill"),
                       ("По уровням вопросов", "cefr")):
        rows = db.accuracy_by(con, u["id"], col)
        if rows:
            lines.append(f"\n<b>{title}</b>")
            lines += capped([f"• {esc(str(r['k']))}: {round(100 * r['ok'] / r['n'])}% ({r['ok']}/{r['n']})"
                             for r in rows])
    memos = db.memo_views(con, u["id"], since)
    if memos:
        lines.append("\n<b>Открывал памятки (14 дней)</b>")
        lines += capped([f"• {esc(r['k'])}: {r['n']}" for r in memos], 6)
    if len(lines) == base:
        lines.append("\nОтветов пока нет.")
    dyn = an.weekly_lines(con, today(), user_id=u["id"])
    if dyn:
        lines += ["", "<b>Динамика по неделям (точность)</b>", "<pre>" + "\n".join(dyn) + "</pre>"]
    return "\n".join(lines)


def group_report_text(g):
    since = (today() - timedelta(days=13)).isoformat()
    members = db.students_overview(con, since, g["id"])
    lines = [f"<b>Группа {esc(g['name'])}</b>" + (f" (цель: {g['target_cefr']})" if g["target_cefr"] else "")
             + f" — учеников: {len(members)}"]
    topics = db.group_topic_accuracy(con, g["id"], since)
    if topics:
        lines.append("\n<b>Темы группы за 14 дней (от слабых к сильным)</b>")
        lines += capped([f"• {esc(str(r['k']))}: {round(100 * r['ok'] / r['n'])}% ({r['ok']}/{r['n']})"
                         for r in topics])
    else:
        lines.append("\nОтветов за 14 дней пока нет.")
    cutoff = (today() - timedelta(days=4)).isoformat()
    quiet = [r["nickname"] for r in members if not r["last_answer"] or r["last_answer"] < cutoff]
    if quiet:
        lines.append("\n⚠️ <b>Не заходили 5+ дней:</b> " + ", ".join(esc(n) for n in quiet))
    dyn = an.weekly_lines(con, today(), group_id=g["id"])
    if dyn:
        lines += ["", "<b>Динамика группы по неделям (точность)</b>", "<pre>" + "\n".join(dyn) + "</pre>"]
    return "\n".join(lines)


@teacher.message(Command("addgroup"))
async def addgroup(m: Message):
    tokens = rest_of(m).split()
    cefr = None
    if len(tokens) > 1 and tokens[-1].upper() in db.CEFR:
        cefr = tokens[-1].upper()
        tokens = tokens[:-1]
    name = " ".join(tokens)
    if not GROUP_NAME_RE.fullmatch(name or "!"):
        await m.answer("Напишите так: /addgroup название [A1|A2|B1|B2|C1]\nНапример: /addgroup A2 вторник A2\n"
                       "Проще всего через кнопки: «🏷 Группы».")
        return
    if db.get_group(con, name):
        await m.answer("Группа с таким названием уже есть.")
        return
    db.create_group(con, name, cefr)
    await m.answer(f"✅ Группа <b>{esc(name)}</b> создана" + (f" (цель: {cefr})." if cefr else "."))


@teacher.message(Command("setgroup"))
async def setgroup(m: Message):
    parts = m.text.split(maxsplit=2)
    if len(parts) != 3:
        await m.answer("Напишите так: /setgroup ник группа\nЧтобы убрать из группы: /setgroup ник -\n"
                       "Проще всего через кнопки: «👥 Ученики».")
        return
    u = db.get_user_by_nick(con, parts[1])
    if not u or u["role"] != "student":
        await m.answer("Ученик с таким никнеймом не найден. Список: «👥 Ученики».")
        return
    name = " ".join(parts[2].split())
    if name == "-":
        db.set_group(con, u["id"], None)
        await m.answer(f"✅ {esc(u['nickname'])} убран(а) из группы.")
        return
    g = db.get_group(con, name)
    if not g:
        await m.answer("Такой группы нет. Список: «🏷 Группы».")
        return
    db.set_group(con, u["id"], g["id"])
    await m.answer(f"✅ {esc(u['nickname'])} теперь в группе <b>{esc(g['name'])}</b>.")


@teacher.message(Command("delgroup"))
async def delgroup(m: Message):
    g = db.get_group(con, rest_of(m)) if rest_of(m) else None
    if not g:
        await m.answer("Напишите так: /delgroup название. Список: «🏷 Группы».")
        return
    if db.delete_group(con, g["id"]):
        await m.answer(f"✅ Группа {esc(g['name'])} удалена.")
    else:
        await m.answer("В группе есть ученики. Сначала переведите их в другую группу.")


@teacher.message(Command("students"))
async def students(m: Message):
    g = None
    if rest_of(m):
        g = db.get_group(con, rest_of(m))
        if not g:
            await m.answer("Такой группы нет. Список: «🏷 Группы».")
            return
    rows = db.students_overview(con, (today() - timedelta(days=6)).isoformat(), g["id"] if g else None)
    if not rows:
        await m.answer("Учеников пока нет.")
        return
    lines = [f"<b>Ученики{' · ' + esc(g['name']) if g else ''}</b> (ответы за 7 дней)\n"]
    for r in rows:
        acc = f"{round(100 * r['ok'] / r['n'])}%" if r["n"] else "—"
        lines.append(f"• <b>{esc(r['nickname'])}</b>" + (f" [{esc(r['grp'])}]" if r["grp"] and not g else "")
                     + f" — ур. {r['level']} ({db.cefr_for_level(r['level'])}), 🔥{db.effective_streak(r, today())}, "
                       f"ответ: {r['last_answer'] or 'никогда'}, ответов: {r['n']}, верно: {acc}")
    await send_long(m, "\n".join(lines))


@teacher.message(Command("student"))
async def student(m: Message):
    u = db.get_user_by_nick(con, rest_of(m)) if rest_of(m) else None
    if not u or u["role"] != "student":
        await m.answer("Напишите так: /student никнейм (регистр не важен). Или откройте «👥 Ученики».")
        return
    await send_long(m, student_report_text(u))


@teacher.message(Command("group"))
async def group_report(m: Message):
    g = db.get_group(con, rest_of(m)) if rest_of(m) else None
    if not g:
        await m.answer("Напишите так: /group название. Или откройте «🏷 Группы».")
        return
    await send_long(m, group_report_text(g))


# ---------- награды и штрафы командами ----------
KIND_ALIASES = {"xp": "xp", "опыт": "xp", "coins": "coins", "монеты": "coins", "freeze": "freeze",
                "заморозка": "freeze"}
KIND_LABEL = {"xp": "XP", "coins": "🪙", "freeze": "❄️"}


def parse_adjust(m: Message):
    """/cmd ник тип число [причина] -> (ник, тип, число, причина) или None."""
    parts = m.text.split(maxsplit=4)
    if len(parts) < 4:
        return None
    kind = KIND_ALIASES.get(parts[2].lower())
    if kind is None or not parts[3].isdigit() or int(parts[3]) <= 0:
        return None
    return parts[1], kind, int(parts[3]), (parts[4].strip() if len(parts) > 4 else "")


def parse_adjust_group(m: Message):
    """/rewardgroup название группы (можно с пробелами) тип число [причина]."""
    tokens = m.text.split()
    for i in range(2, len(tokens) - 1):
        if tokens[i].lower() in KIND_ALIASES and tokens[i + 1].isdigit() and int(tokens[i + 1]) > 0:
            return (" ".join(tokens[1:i]), KIND_ALIASES[tokens[i].lower()], int(tokens[i + 1]),
                    " ".join(tokens[i + 2:]))
    return None


async def apply_and_notify(bot: Bot, teacher_tg_id, student_row, kind, amount, reason):
    """Начисляет (amount > 0) или списывает (amount < 0) и уведомляет ученика. Возвращает (применено, уведомлён)."""
    t = player(teacher_tg_id)
    applied = db.adjust(con, student_row["id"], kind, amount, reason, t["id"] if t else None, today())
    if applied == 0:
        return 0, False
    sign = "+" if applied > 0 else "−"
    head = "🎁 Учитель наградил тебя" if applied > 0 else "⚠️ Учитель списал"
    text = f"{head}: <b>{sign}{abs(applied)} {KIND_LABEL[kind]}</b>" + (f"\n💬 {esc(reason)}" if reason else "")
    try:
        await bot.send_message(student_row["telegram_id"], text)
        return applied, True
    except Exception:
        return applied, False


@teacher.message(Command("reward"))
async def reward(m: Message, bot: Bot):
    args = parse_adjust(m)
    if not args:
        await m.answer("Напишите так: /reward ник тип число [причина]\n"
                       "Тип: xp, coins или freeze. Пример: /reward anna xp 50 Отличная работа на уроке\n"
                       "Проще всего через кнопки: «🎁 Награды».")
        return
    nick, kind, amount, reason = args
    u = db.get_user_by_nick(con, nick)
    if not u or u["role"] != "student":
        await m.answer("Ученик с таким никнеймом не найден. Список: «👥 Ученики».")
        return
    applied, notified = await apply_and_notify(bot, m.from_user.id, u, kind, amount, reason)
    if applied == 0:
        await m.answer("Ничего не изменилось (достигнут максимум заморозок).")
        return
    ch = db.get_character(con, u["id"])
    await m.answer(f"✅ {esc(u['nickname'])}: +{applied} {KIND_LABEL[kind]}. Сейчас: XP {ch['xp']}, "
                   f"🪙 {ch['coins']}, ❄️ {ch['freezes']}, ур. {ch['level']}."
                   + ("" if notified else "\n(Ученик не получил уведомление: он ещё не писал боту или заблокировал его.)"))


@teacher.message(Command("penalty"))
async def penalty(m: Message, bot: Bot):
    args = parse_adjust(m)
    if not args:
        await m.answer("Напишите так: /penalty ник coins|freeze число [причина]\n"
                       "Пример: /penalty anna coins 5 Не сделана домашка\nПроще всего через кнопки: «🎁 Награды».")
        return
    nick, kind, amount, reason = args
    if kind == "xp":
        await m.answer("Опыт не списывается: уровень ученика не должен падать, это сильно демотивирует. "
                       "Можно списать монеты (coins) или заморозку серии (freeze).")
        return
    u = db.get_user_by_nick(con, nick)
    if not u or u["role"] != "student":
        await m.answer("Ученик с таким никнеймом не найден. Список: «👥 Ученики».")
        return
    applied, notified = await apply_and_notify(bot, m.from_user.id, u, kind, -amount, reason)
    if applied == 0:
        await m.answer("Ничего не изменилось: у ученика уже ноль.")
        return
    ch = db.get_character(con, u["id"])
    await m.answer(f"✅ {esc(u['nickname'])}: −{abs(applied)} {KIND_LABEL[kind]}. Сейчас: 🪙 {ch['coins']}, "
                   f"❄️ {ch['freezes']}."
                   + ("" if notified else "\n(Ученик не получил уведомление: он ещё не писал боту или заблокировал его.)"))


@teacher.message(Command("rewardgroup"))
async def rewardgroup(m: Message, bot: Bot):
    args = parse_adjust_group(m)
    if not args:
        await m.answer("Напишите так: /rewardgroup группа тип число [причина]\n"
                       "Пример: /rewardgroup A2 вторник coins 5 Все сделали домашку\n"
                       "Проще всего через кнопки: «🎁 Награды».")
        return
    name, kind, amount, reason = args
    g = db.get_group(con, name)
    if not g:
        await m.answer("Такой группы нет. Список: «🏷 Группы».")
        return
    members = db.group_students(con, g["id"])
    if not members:
        await m.answer("В группе нет учеников.")
        return
    done = notified_n = 0
    for u in members:
        applied, notified = await apply_and_notify(bot, m.from_user.id, u, kind, amount, reason)
        done += applied > 0
        notified_n += notified
    await m.answer(f"✅ Группа {esc(g['name'])}: +{amount} {KIND_LABEL[kind]} получили {done} из {len(members)} "
                   f"учеников, уведомлены: {notified_n}.")


# ======================= команды учителя: домашние задания =======================
DUE_CHOICES = {"1": "завтра", "3": "через 3 дня", "7": "через неделю", "0": "без дедлайна"}


def due_kb():
    return ikb(*[[(v.capitalize(), f"nhw:due:{k}")] for k, v in DUE_CHOICES.items()], [("❌ Отмена", "nhw:cancel")])


def newhw_type_content():
    return "<b>Новое домашнее задание.</b> Какого типа?", ikb(
        [("📝 Тест из банка (проверяет бот)", "nhw:type:quiz")],
        [("✍️ Авторское задание", "nhw:type:manual")], [("❌ Отмена", "nhw:cancel")])


@teacher.message(Command("newhw"))
@teacher.message(F.text == BTN_NEWHW)
async def newhw(m: Message, state: FSMContext):
    await state.clear()
    await tidy(m)
    text, kb = newhw_type_content()
    await m.answer(text, reply_markup=kb)


@teacher.callback_query(F.data == "nhw:start")
async def nhw_start(cb: CallbackQuery, state: FSMContext):
    await state.clear()
    await cb.answer()
    text, kb = newhw_type_content()
    await edit(cb, text, kb)


@teacher.callback_query(F.data.startswith("nhw:preg:"))
async def nhw_preset_group(cb: CallbackQuery, state: FSMContext):
    """Задание, созданное из карточки группы: группа уже выбрана."""
    await state.clear()
    await state.update_data(group_id=int(cb.data.split(":")[2]), preset_group=True)
    await cb.answer()
    text, kb = newhw_type_content()
    await edit(cb, text, kb)


@teacher.callback_query(F.data == "nhw:cancel")
async def nhw_cancel(cb: CallbackQuery, state: FSMContext):
    await state.clear()
    await cb.answer()
    await edit(cb, "Отменено.")


@teacher.callback_query(F.data.startswith("nhw:type:"))
async def nhw_type(cb: CallbackQuery, state: FSMContext):
    await state.update_data(kind=cb.data.split(":")[2])
    await cb.answer()
    if (await state.get_data()).get("preset_group"):
        await state.set_state(NewHW.title)
        await edit(cb, "Напишите <b>название</b> задания (например: «Past Simple, неделя 3»).")
        return
    rows = [[(f"{g['name']} ({g['members']})", f"nhw:grp:{g['id']}")] for g in db.groups_overview(con)]
    rows.append([("Все ученики", "nhw:grp:0")])
    await edit(cb, "Кому задание?", ikb(*rows))


@teacher.callback_query(F.data.startswith("nhw:grp:"))
async def nhw_group(cb: CallbackQuery, state: FSMContext):
    gid = int(cb.data.split(":")[2])
    await state.update_data(group_id=gid or None)
    await state.set_state(NewHW.title)
    await cb.answer()
    await edit(cb, "Напишите <b>название</b> задания (например: «Past Simple, неделя 3»).")


LEVEL_CHIPS = ["Все", "A1", "A2", "B1", "B2", "C1"]


def topic_picker_content(d, page):
    """Тем в банке могут быть сотни: показываем по 8 с листанием, поиском по названию и фильтром по уровню."""
    cefr, query = d.get("tf"), d.get("tq")
    topics = db.topic_stats(con, cefr, query)
    pages = max(1, -(-len(topics) // PAGE))
    page = max(0, min(page, pages - 1))
    info = []
    if cefr:
        info.append(f"уровень {cefr}")
    if query:
        info.append(f"поиск «{esc(query)}»")
    text = (f"📚 <b>Тема для теста</b>\nТем найдено: {len(topics)}" + (f" ({', '.join(info)})" if info else "")
            + (f" · страница {page + 1} из {pages}" if pages > 1 else "")
            + ("\nНичего не найдено: измените поиск или уровень." if not topics else ""))
    rows = [[((f"✔️ {c}" if (cefr or "Все") == c else c), f"nhw:tl:{c}") for c in LEVEL_CHIPS]]
    rows.append([("🔎 Найти по названию", "nhw:ts")] + ([("✖️ Сбросить поиск", "nhw:tc")] if query else []))
    rows.append([("🎲 Любая тема" + (f" ({cefr})" if cefr else " (весь банк)"), "nhw:topic:any")])
    rows += [[(f"{t[:42]} · {n}", f"nhw:topic:{db.topic_key(t)}")] for t, n in topics[page * PAGE:(page + 1) * PAGE]]
    rows += nav_row(page, pages, "nhw:tp")
    rows.append([("❌ Отмена", "nhw:cancel")])
    return text, ikb(*rows)


@teacher.callback_query(F.data.startswith("nhw:tp:"))
async def nhw_topic_page(cb: CallbackQuery, state: FSMContext):
    await cb.answer()
    text, kb = topic_picker_content(await state.get_data(), int(cb.data.split(":")[2]))
    await edit(cb, text, kb)


@teacher.callback_query(F.data.startswith("nhw:tl:"))
async def nhw_topic_level(cb: CallbackQuery, state: FSMContext):
    level = cb.data.split(":")[2]
    await state.update_data(tf=None if level == "Все" else level)
    await cb.answer()
    text, kb = topic_picker_content(await state.get_data(), 0)
    await edit(cb, text, kb)


@teacher.callback_query(F.data == "nhw:tc")
async def nhw_topic_clear(cb: CallbackQuery, state: FSMContext):
    await state.update_data(tq=None)
    await cb.answer()
    text, kb = topic_picker_content(await state.get_data(), 0)
    await edit(cb, text, kb)


@teacher.callback_query(F.data == "nhw:ts")
async def nhw_topic_search(cb: CallbackQuery, state: FSMContext):
    await state.set_state(NewHW.search)
    await state.update_data(prompt_id=cb.message.message_id)
    await cb.answer()
    await edit(cb, "🔎 Напишите часть названия темы (например, «past» или «артикл»).",
               ikb([("⬅️ Назад к списку", "nhw:tp:0")]))


@teacher.message(NewHW.search, F.text, ~F.text.startswith("/"))
async def nhw_topic_search_input(m: Message, state: FSMContext):
    await tidy(m)
    await state.update_data(tq=m.text.strip()[:40])
    await state.set_state(None)
    text, kb = topic_picker_content(await state.get_data(), 0)
    await edit_prompt(m.bot, m.chat.id, state, text, kb)


@teacher.message(NewHW.title, F.text, ~F.text.startswith("/"))
async def nhw_title(m: Message, state: FSMContext):
    await state.update_data(title=m.text.strip()[:80])
    d = await state.get_data()
    if d.get("kind") == "quiz":
        if not db.topic_stats(con):
            await state.clear()
            await m.answer("В банке пока нет вопросов. Загрузите таблицу с вопросами.")
            return
        await state.update_data(tf=None, tq=None)
        await state.set_state(None)
        text, kb = topic_picker_content({}, 0)
        await m.answer(text, reply_markup=kb)
    else:
        await state.set_state(NewHW.desc)
        await m.answer("Напишите <b>условие</b> задания: что именно нужно сделать и как сдать.")


@teacher.message(NewHW.desc, F.text, ~F.text.startswith("/"))
async def nhw_desc(m: Message, state: FSMContext):
    await state.update_data(description=m.text.strip())
    await state.set_state(None)
    await m.answer("Дедлайн?", reply_markup=due_kb())


@teacher.callback_query(F.data.startswith("nhw:topic:"))
async def nhw_topic(cb: CallbackQuery, state: FSMContext):
    d = await state.get_data()
    key = cb.data.split(":")[2]
    topic = None
    if key != "any":
        topic = db.topic_by_key(con, key)
        if topic is None:
            await cb.answer("Тема не найдена (таблица могла обновиться). Откройте список заново.", show_alert=True)
            return
    cefr = d.get("tf")
    avail = db.count_questions(con, topic, cefr)
    if not avail:
        await cb.answer("В этой теме нет активных вопросов выбранного уровня.", show_alert=True)
        return
    await state.update_data(topic=topic, hw_cefr=cefr, avail=avail)
    await cb.answer()
    options = [n for n in (5, 10, 15, 20, 30) if n < avail]
    buttons = [(str(n), f"nhw:cnt:{n}") for n in options] + [(f"Все ({avail})" if avail <= 60 else "60", f"nhw:cnt:{min(avail, 60)}")]
    await edit(cb, f"Тема: <b>{esc(topic) if topic else 'весь банк'}</b>" + (f" · уровень {cefr}" if cefr else "")
               + f"\nДоступно вопросов: {avail}. Сколько взять в тест?", ikb(buttons[:6], [("⬅️ Другая тема", "nhw:tp:0")]))


@teacher.callback_query(F.data.startswith("nhw:cnt:"))
async def nhw_count(cb: CallbackQuery, state: FSMContext):
    d = await state.get_data()
    await state.update_data(count=min(int(cb.data.split(":")[2]), d.get("avail") or 60))
    await cb.answer()
    await edit(cb, "Дедлайн?", due_kb())


@teacher.callback_query(F.data.startswith("nhw:due:"))
async def nhw_due(cb: CallbackQuery, state: FSMContext):
    days = int(cb.data.split(":")[2])
    due = (today() + timedelta(days=days)).isoformat() if days else None
    await state.update_data(due=due)
    d = await state.get_data()
    await cb.answer()
    who = db.group_name(con, d["group_id"]) if d.get("group_id") else "все ученики"
    lines = ["<b>Проверьте задание:</b>", f"Тип: {'тест из банка' if d['kind'] == 'quiz' else 'авторское'}",
             f"Кому: {esc(who)}", f"Название: {esc(d['title'])}"]
    if d["kind"] == "quiz":
        lines.append(f"Тема: {esc(d['topic']) if d.get('topic') else 'весь банк'}"
                     + (f", уровень {d['hw_cefr']}" if d.get("hw_cefr") else "") + f", вопросов: {d['count']}")
    else:
        lines.append(f"Условие: {esc(d['description'])}")
    lines.append(f"Срок: {fmt_due(due)}")
    await edit(cb, "\n".join(lines), ikb([("✅ Создать", "nhw:ok"), ("❌ Отмена", "nhw:cancel")]))


@teacher.callback_query(F.data == "nhw:ok")
async def nhw_create(cb: CallbackQuery, state: FSMContext, bot: Bot):
    d = await state.get_data()
    await cb.answer()
    if not d.get("title") or not d.get("kind"):
        await edit(cb, "Что-то пошло не так, начните заново: /newhw")
        return
    await state.clear()
    t = player(cb.from_user.id)
    qids = []
    if d["kind"] == "quiz":
        qids = db.pick_homework_questions(con, d.get("topic"), d["count"], d.get("hw_cefr"))
        if not qids:
            await edit(cb, "По этой теме нет активных вопросов. Выберите другую: /newhw")
            return
    hw_id = db.create_homework(con, d["kind"], d["title"], d.get("description"), d.get("topic"), d.get("group_id"),
                               d.get("due"), t["id"] if t else None, qids)
    notified = 0
    students_ = db.students_in_scope(con, d.get("group_id"))
    for u in students_:
        try:
            await bot.send_message(u["telegram_id"], f"📝 <b>Новое задание:</b> {esc(d['title'])} · "
                                                     f"{fmt_due(d.get('due'))}\nОткрой «📝 Домашка».")
            notified += 1
        except Exception:
            pass
    note = f" (в тесте {len(qids)} вопросов)" if qids and len(qids) < d["count"] else ""
    await edit(cb, f"✅ Задание #{hw_id} создано{note}. Учеников в списке: {len(students_)}, "
                   f"уведомлено: {notified}.")


def teacher_hw_content():
    rows = db.homework_active(con)
    pending = len(db.hw_pending(con))
    kb = [[("➕ Создать задание", "nhw:start")]]
    if pending:
        kb.append([(f"📥 На проверке ({pending})", "rv:list")])
    for h in rows:
        prog = db.hw_progress(con, h)
        done = sum(1 for p in prog if p["status"] == "done")
        kb.append([(f"#{h['id']} {h['title'][:28]} · {h['grp'] or 'все'} · {done}/{len(prog)}",
                    f"hwt:open:{h['id']}")])
    text = "📝 <b>Задания</b> (выполнили/всего):" if rows else "📝 <b>Активных заданий нет.</b> Создайте первое:"
    return text, ikb(*kb)


@teacher.callback_query(F.data == "hwt:list")
async def teacher_hw_back(cb: CallbackQuery):
    await cb.answer()
    text, kb = teacher_hw_content()
    await edit(cb, text, kb)


@teacher.callback_query(F.data.startswith("hwt:open:"))
async def teacher_hw_open(cb: CallbackQuery):
    hw = db.get_homework(con, int(cb.data.split(":")[2]))
    await cb.answer()
    if not hw:
        return
    lines = [f"<b>#{hw['id']} {esc(hw['title'])}</b> · {'тест' if hw['kind'] == 'quiz' else 'авторское'} · "
             f"{esc(db.group_name(con, hw['group_id']) or 'все ученики')} · {fmt_due(hw['due_date'])}"]
    if hw["kind"] == "manual" and hw["description"]:
        lines.append(esc(hw["description"]))
    lines.append("")
    for p in db.hw_progress(con, hw):
        lines.append(f"• {esc(p['nickname'])} — " + hw_label(p["status"], p["score"], p["total"], p["late"],
                                                           hw["kind"], hw["due_date"]))
    kb = ikb([("⚙️ Ученики", f"hwt:stu:{hw['id']}")],
             [("⬅️ Назад", "hwt:list"), ("📦 Закрыть", f"hwt:close:{hw['id']}")])
    text = "\n".join(lines)
    if len(text) <= 3900:
        await edit(cb, text, kb)
    else:
        await send_long(cb.message, text, reply_markup=kb)


@teacher.callback_query(F.data.startswith("hwt:close:"))
async def teacher_hw_close(cb: CallbackQuery):
    db.hw_close(con, int(cb.data.split(":")[2]))
    await cb.answer("Закрыто")
    await edit(cb, "📦 Задание закрыто: ученики его больше не видят. Данные сохранены.",
               ikb([("⬅️ К списку", "hwt:list")]))


def student_actions_content(hw, u):
    st = db.hw_get_status(con, hw["id"], u["id"])
    label = hw_label(st["status"] if st else None, st["score"] if st else None, st["total"] if st else None,
                     st["late"] if st else 0, hw["kind"], hw["due_date"])
    return (f"⚙️ <b>{esc(u['nickname'])}</b> · {esc(hw['title'])}\nСтатус: {label}",
            ikb([("✅ Отметить выполненным", f"hwt:done:{hw['id']}:{u['id']}")],
                [("🔄 Сбросить попытку", f"hwt:reset:{hw['id']}:{u['id']}")],
                [("⬅️ Назад", f"hwt:stu:{hw['id']}")]))


@teacher.callback_query(F.data.startswith("hwt:stu:"))
async def hw_students(cb: CallbackQuery):
    hw = db.get_homework(con, int(cb.data.split(":")[2]))
    await cb.answer()
    if not hw:
        return
    rows = [[(f"{p['nickname']} — " + hw_label(p["status"], p["score"], p["total"], p["late"], hw["kind"],
                                                hw["due_date"]), f"hwt:act:{hw['id']}:{p['id']}")]
            for p in db.hw_progress(con, hw)[:40]]
    rows.append([("⬅️ Назад", f"hwt:open:{hw['id']}")])
    await edit(cb, f"⚙️ <b>#{hw['id']} {esc(hw['title'])}</b>\nВыберите ученика:", ikb(*rows))


@teacher.callback_query(F.data.startswith("hwt:act:"))
async def hw_student_actions(cb: CallbackQuery):
    _, _, hid, uid = cb.data.split(":")
    hw, u = db.get_homework(con, int(hid)), user_by_id(int(uid))
    await cb.answer()
    if hw and u:
        text, kb = student_actions_content(hw, u)
        await edit(cb, text, kb)


@teacher.callback_query(F.data.startswith("hwt:done:"))
async def hw_done_button(cb: CallbackQuery, bot: Bot):
    _, _, hid, uid = cb.data.split(":")
    hw, u = db.get_homework(con, int(hid)), user_by_id(int(uid))
    if not hw or not u:
        await cb.answer()
        return
    result = await mark_done(bot, cb.from_user.id, hw, u)
    await cb.answer("✅ Отмечено" if result else "Уже отмечено выполненным")
    text, kb = student_actions_content(hw, u)
    await edit(cb, text, kb)


@teacher.callback_query(F.data.startswith("hwt:reset:"))
async def hw_reset_button(cb: CallbackQuery):
    _, _, hid, uid = cb.data.split(":")
    hw, u = db.get_homework(con, int(hid)), user_by_id(int(uid))
    if not hw or not u:
        await cb.answer()
        return
    db.hw_reset(con, hw["id"], u["id"])
    await cb.answer("🔄 Попытка сброшена")
    text, kb = student_actions_content(hw, u)
    await edit(cb, text, kb)


@teacher.callback_query(F.data == "rv:list")
async def pending_list(cb: CallbackQuery):
    rows = db.hw_pending(con)
    await cb.answer()
    if not rows:
        await edit(cb, "📥 Работ на проверке нет.", ikb([("⬅️ Назад", "hwt:list")]))
        return
    kb = [[(f"{r['nickname']} — {r['title'][:30]}", f"rv:open:{r['homework_id']}:{r['user_id']}")] for r in rows[:30]]
    kb.append([("⬅️ Назад", "hwt:list")])
    await edit(cb, f"📥 <b>На проверке ({len(rows)})</b>\nВыберите работу, чтобы открыть её и принять или вернуть:",
               ikb(*kb))


@teacher.callback_query(F.data.startswith("rv:open:"))
async def pending_open(cb: CallbackQuery, bot: Bot):
    _, _, hid, uid = cb.data.split(":")
    hw, u, st = db.get_homework(con, int(hid)), user_by_id(int(uid)), db.hw_get_status(con, int(hid), int(uid))
    if not hw or not u or not st or st["status"] != "submitted" or not st["sub_msg"]:
        await cb.answer("Работа недоступна: её уже проверили или ссылка на сообщение потеряна.", show_alert=True)
        return
    try:
        await bot.send_message(cb.message.chat.id, f"📥 <b>{esc(hw['title'])}</b> (#{hw['id']})\n"
                                                   f"От: <b>{esc(u['nickname'])}</b>")
        await bot.copy_message(cb.message.chat.id, st["sub_chat"], st["sub_msg"], reply_markup=ikb(
            [("✅ Принять", f"hwr:acc:{hid}:{uid}"), ("🔁 Доработать", f"hwr:rew:{hid}:{uid}")]))
        await cb.answer()
    except Exception:
        await cb.answer("Не удалось открыть работу: ученик мог удалить своё сообщение.", show_alert=True)


async def notify_student(bot: Bot, u, text):
    try:
        await bot.send_message(u["telegram_id"], text)
        return True
    except Exception:
        return False


def accept_manual(teacher_row, u, hw):
    """Принять авторское задание: статус done + награда. Возвращает текст награды."""
    db.hw_set_status(con, hw["id"], u["id"], "done", completed_at=db.utc_now())
    reason = f"Домашка: {hw['title']}"
    tid = teacher_row["id"] if teacher_row else None
    xp = db.adjust(con, u["id"], "xp", db.HW_MANUAL_XP, reason, tid, today())
    coins = db.adjust(con, u["id"], "coins", db.HW_MANUAL_COINS, reason, tid, today())
    return f"+{xp} XP, +{coins} 🪙"


@teacher.callback_query(F.data.startswith("hwr:"))
async def hw_review(cb: CallbackQuery, state: FSMContext, bot: Bot):
    _, action, hw_id, uid = cb.data.split(":")
    hw = db.get_homework(con, int(hw_id))
    u = con.execute("SELECT * FROM users WHERE id=?", (int(uid),)).fetchone()
    st = db.hw_get_status(con, int(hw_id), int(uid))
    if not hw or not u:
        await cb.answer("Не найдено")
        return
    if st and st["status"] == "done":
        await cb.answer("Это задание уже принято")
        return
    await cb.answer()
    try:
        await cb.message.edit_reply_markup(reply_markup=None)
    except Exception:
        pass
    if action == "acc":
        reward_text = accept_manual(player(cb.from_user.id), u, hw)
        sent = await notify_student(bot, u, f"✅ Учитель принял задание «{esc(hw['title'])}»: {reward_text}")
        await cb.message.answer(f"✅ Принято: {esc(u['nickname'])} ({reward_text})."
                                + ("" if sent else " Ученик не получил уведомление."))
    else:
        db.hw_set_status(con, hw["id"], u["id"], "rework")
        await notify_student(bot, u, f"🔁 Задание «{esc(hw['title'])}» нужно доработать. Открой «📝 Домашка».")
        await state.set_state(NewHW.comment)
        await state.update_data(c_hw=hw["id"], c_uid=u["id"])
        await cb.message.answer(f"Статус: на доработке ({esc(u['nickname'])}). Напишите комментарий ученику "
                                f"(что исправить) или «-», чтобы без комментария.")


@teacher.message(NewHW.comment, F.text, ~F.text.startswith("/"))
async def hw_comment(m: Message, state: FSMContext, bot: Bot):
    d = await state.get_data()
    await state.clear()
    u = con.execute("SELECT * FROM users WHERE id=?", (d.get("c_uid") or 0,)).fetchone()
    hw = db.get_homework(con, d.get("c_hw") or 0)
    if not u or not hw:
        return
    if m.text.strip() == "-":
        await m.answer("Хорошо, без комментария.")
        return
    db.hw_set_status(con, hw["id"], u["id"], "rework", teacher_comment=m.text.strip())
    sent = await notify_student(bot, u, f"💬 Комментарий учителя к «{esc(hw['title'])}»:\n{esc(m.text.strip())}")
    await m.answer("✅ Комментарий отправлен." if sent else "Комментарий сохранён (ученик увидит его в «Домашке»).")


def hw_args(m: Message):
    parts = m.text.split()
    if len(parts) != 3 or not parts[1].isdigit():
        return None
    hw, u = db.get_homework(con, int(parts[1])), db.get_user_by_nick(con, parts[2])
    return (hw, u) if hw and u and u["role"] == "student" else None


async def mark_done(bot: Bot, teacher_tg, hw, u):
    """Отмечает задание выполненным. Возвращает текст-подтверждение или None, если уже выполнено."""
    st = db.hw_get_status(con, hw["id"], u["id"])
    if st and st["status"] == "done":
        return None
    if hw["kind"] == "manual":
        reward_text = accept_manual(player(teacher_tg), u, hw)
        await notify_student(bot, u, f"✅ Учитель принял задание «{esc(hw['title'])}»: {reward_text}")
        return f"✅ {esc(u['nickname'])}: задание #{hw['id']} принято ({reward_text})."
    db.hw_set_status(con, hw["id"], u["id"], "done", completed_at=db.utc_now())
    return f"✅ {esc(u['nickname'])}: тест #{hw['id']} отмечен выполненным (без оценки и награды)."


@teacher.message(Command("hwdone"))
async def hwdone(m: Message, bot: Bot):
    args = hw_args(m)
    if not args:
        await m.answer("Напишите так: /hwdone номер_задания ник (номер виден в «📝 Задания»). Или кнопками: "
                       "«📝 Задания» → задание → «⚙️ Ученики».")
        return
    result = await mark_done(bot, m.from_user.id, *args)
    await m.answer(result or "Это задание у ученика уже отмечено выполненным.")


@teacher.message(Command("hwreset"))
async def hwreset(m: Message):
    args = hw_args(m)
    if not args:
        await m.answer("Напишите так: /hwreset номер_задания ник")
        return
    hw, u = args
    db.hw_reset(con, hw["id"], u["id"])
    await m.answer(f"✅ Попытка {esc(u['nickname'])} по заданию #{hw['id']} сброшена: можно пройти заново.")


# ======================= загрузка вопросов и памяток =======================
@teacher.message(F.document)
async def on_document(m: Message, bot: Bot):
    if not (m.document.file_name or "").lower().endswith(".xlsx"):
        await m.answer("Пришлите файл в формате .xlsx")
        return
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "q.xlsx")
        await bot.download(m.document, destination=path)
        try:
            q_ok, q_prob, c_ok, c_prob = db.import_workbook(con, path)
        except Exception as e:
            await m.answer(f"Не удалось прочитать файл: {esc(str(e))}")
            return
    problems = q_prob + c_prob
    text = f"✅ Загружено вопросов: {q_ok}, памяток: {c_ok}. Тем в банке: {len(db.topic_stats(con))}"
    if problems:
        text += f"\n⚠️ Пропущено строк: {len(problems)}\n" + "\n".join(esc(p) for p in problems[:15])
    similar = db.similar_topics(con)
    if similar:
        text += ("\n\n⚠️ <b>Похожие названия тем</b> (отличаются регистром или пробелами, бот считает их разными, "
                 "возможно, опечатка):\n" + "\n".join("• " + " / ".join(f"«{esc(t)}»" for t in grp)
                                                         for grp in similar[:6]))
    await m.answer(text)


@teacher.message(F.text)
async def teacher_fallback(m: Message):
    await m.answer("Используйте кнопки внизу: «👥 Ученики», «🏷 Группы», «📝 Задания», «🎁 Награды», «📊 Сводка». "
                   "Список команд: /admin.")


@router.message(F.text)
async def fallback(m: Message):
    await m.answer("Нажми кнопку внизу: «🎯 Квиз», «👤 Профиль», «📖 Памятки» или «📝 Домашка». "
                   "Если что-то не работает, напиши /start.")


# ======================= запуск =======================
@router.error()
async def on_error(event: ErrorEvent):
    logging.exception("Ошибка при обработке обновления", exc_info=event.exception)
    msg = event.update.message or (event.update.callback_query.message if event.update.callback_query else None)
    if msg:
        try:
            await msg.answer("Ой, что-то пошло не так 😅 Нажми /start и попробуй ещё раз.")
        except Exception:
            pass
    return True


def make_dispatcher():
    # SimpleEventIsolation: действия одного ученика обрабатываются строго по очереди,
    # поэтому быстрые двойные нажатия не ломают квиз.
    dp = Dispatcher(storage=MemoryStorage(), events_isolation=SimpleEventIsolation())
    dp.include_router(teacher)
    dp.include_router(router)
    return dp


async def setup_commands(bot: Bot):
    """Меню команд, которое Telegram показывает по кнопке «/»."""
    await bot.set_my_commands(STUDENT_COMMANDS)
    try:
        await bot.set_my_short_description("Английский в игровой форме: квиз каждый день, уровни A1–C1, памятки и домашка")
        await bot.set_my_description(
            "Английский в игровой форме 🎮\n\nКаждый день короткий квиз, уровни от A1 до C1, памятки по темам "
            "и домашние задания от учителя. Нажми «Начать» и придумай никнейм!")
    except Exception:
        pass
    for tid in TEACHERS:
        try:
            await bot.set_my_commands(TEACHER_COMMANDS, scope=BotCommandScopeChat(chat_id=tid))
        except Exception:
            pass  # учитель ещё не писал боту: команды установятся при его первом /start


def startup_import():
    """Читает questions.xlsx из папки бота. По умолчанию только при первом запуске (когда в базе нет вопросов):
    дальше вопросы обновляются отправкой файла боту, и перезапуск не откатывает их к старой версии.
    Режим IMPORT_QUESTIONS_ON_START=always загружает файл при каждом запуске."""
    if not os.path.exists(QUESTIONS_FILE):
        return
    have = con.execute("SELECT COUNT(*) FROM questions").fetchone()[0]
    if have and os.getenv("IMPORT_QUESTIONS_ON_START", "first").strip().lower() != "always":
        print(f"В базе уже есть вопросы ({have}): файл {QUESTIONS_FILE} при запуске не читаю.")
        return
    q_ok, q_prob, c_ok, c_prob = db.import_workbook(con, QUESTIONS_FILE)
    print(f"Из {QUESTIONS_FILE} загружено вопросов: {q_ok}, памяток: {c_ok}")
    for p in q_prob + c_prob:
        print("  Пропущено:", p)


async def main():
    logging.basicConfig(level=logging.INFO)
    if not TOKEN:
        raise SystemExit("Не найден BOT_TOKEN. Откройте settings.env и вставьте токен от @BotFather.")
    db.drop_teacher_characters(con)
    print("База данных:", os.path.abspath(DB_PATH))
    print("Учителя (TEACHER_IDS):", sorted(TEACHERS) or "НЕ ЗАДАНЫ — укажите TEACHER_IDS")
    startup_import()
    bot = Bot(TOKEN, default=DefaultBotProperties(parse_mode=ParseMode.HTML))
    await setup_commands(bot)
    scheduler_task = asyncio.create_task(sch.run(bot, con, SCHED))   # напоминания, дайджест, сигналы
    print(f"Автоматика: напоминания в {SCHED.remind_hour}:00, дайджест по {WEEKDAYS[SCHED.digest_weekday]} "
          f"в {SCHED.digest_hour}:00")
    print("Бот запущен. Остановить: Ctrl+C")
    try:
        await make_dispatcher().start_polling(bot)
    finally:
        scheduler_task.cancel()


if __name__ == "__main__":
    asyncio.run(main())
