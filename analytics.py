"""Аналитика для учителя: флаги риска, динамика по неделям, недельный дайджест, экспорт в Excel.
Модуль работает только с базой данных (без Telegram), поэтому его удобно проверять на тестовых данных."""
from collections import defaultdict
from datetime import date, timedelta
from html import escape as esc

from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

import db

# ---- пороги: можно менять ----
ABSENT_DAYS = 5          # не занимается столько дней и больше → флаг «пропал»
NEVER_DAYS = 3           # зарегистрировался давно, но ни разу не занимался
DECLINE_POINTS = 15      # точность упала на столько процентных пунктов и больше
MIN_ANSWERS = 8          # минимум ответов в каждой неделе, чтобы сравнивать точность
OVERDUE_MIN = 2          # просрочено столько заданий и больше → флаг
DROPOUT_MIN_STARTS = 3   # минимум начатых квизов за 14 дней, чтобы судить, что ученик их бросает
WEEKS_DEFAULT = 6


def d(s):
    return date.fromisoformat(s)


def pct(ok, n):
    return round(100 * ok / n) if n else None


def pct_text(ok, n):
    return f"{pct(ok, n)}%" if n else "—"


def monday(day):
    return day - timedelta(days=day.weekday())


def bar(value, width=10):
    """Текстовая полоска 0–100%."""
    if value is None:
        return "░" * width
    filled = max(0, min(width, round(width * value / 100)))
    return "█" * filled + "░" * (width - filled)


def split_text(text, limit=3500):
    """Режет длинный текст по строкам на части, пригодные для сообщений Telegram."""
    chunks, cur = [], ""
    for line in text.split("\n"):
        if len(cur) + len(line) + 1 > limit and cur:
            chunks.append(cur.rstrip("\n"))
            cur = ""
        cur += line + "\n"
    if cur.strip():
        chunks.append(cur.rstrip("\n"))
    return chunks


# =====================================================================================
#  Выборки
# =====================================================================================
def answer_rows(con, since_day, until_day=None, user_id=None, group_id=None):
    """Ответы учеников за период: (user_id, day, is_correct, topic, skill)."""
    sql = ("SELECT e.user_id, e.day, e.is_correct, e.topic, e.skill FROM events e JOIN users u ON u.id=e.user_id "
           "WHERE e.event_type='answer' AND u.role='student' AND u.is_active=1 AND e.day>=?")
    params = [since_day.isoformat()]
    if until_day:
        sql += " AND e.day<=?"
        params.append(until_day.isoformat())
    if user_id is not None:
        sql += " AND e.user_id=?"
        params.append(user_id)
    if group_id is not None:
        sql += " AND u.group_id=?"
        params.append(group_id)
    return con.execute(sql, params).fetchall()


def totals(rows):
    n = len(rows)
    return n, sum(r["is_correct"] or 0 for r in rows)


# =====================================================================================
#  Динамика по неделям
# =====================================================================================
def weekly_stats(con, today, weeks=WEEKS_DEFAULT, user_id=None, group_id=None):
    """Список недель (от старой к новой): начало недели, ответов, верных, число активных учеников."""
    first = monday(today) - timedelta(weeks=weeks - 1)
    buckets = {first + timedelta(weeks=i): {"n": 0, "ok": 0, "users": set()} for i in range(weeks)}
    for r in answer_rows(con, first, user_id=user_id, group_id=group_id):
        b = buckets.get(monday(d(r["day"])))
        if b is not None:
            b["n"] += 1
            b["ok"] += r["is_correct"] or 0
            b["users"].add(r["user_id"])
    return [{"week": w, "n": b["n"], "ok": b["ok"], "active": len(b["users"])} for w, b in sorted(buckets.items())]


def weekly_lines(con, today, weeks=WEEKS_DEFAULT, user_id=None, group_id=None):
    """Текстовая «диаграмма» динамики: по строке на неделю."""
    stats = weekly_stats(con, today, weeks, user_id, group_id)
    while stats and not stats[0]["n"]:      # недели до первого ответа не показываем
        stats.pop(0)
    if not stats:
        return []
    lines = []
    for s in stats:
        label = f"{s['week'].strftime('%d.%m')}"
        acc = pct(s["ok"], s["n"])
        extra = f" · активных: {s['active']}" if group_id is not None else ""
        lines.append(f"{label} {bar(acc)} {pct_text(s['ok'], s['n']):>4} · {s['n']} отв.{extra}")
    return lines


# =====================================================================================
#  Флаги риска
# =====================================================================================
def _iso_week(day):
    y, w, _ = day.isocalendar()
    return f"{y}-{w:02d}"


def risk_flags(con, today, end=None, user_id=None):
    """Возвращает {id ученика: [(код, текст, ключ_эпизода)]} только для тех, у кого есть сигналы.
    Ключ эпизода нужен, чтобы не присылать одно и то же предупреждение каждый день."""
    end = end or today
    cur_start, prev_start, prev_end = end - timedelta(days=6), end - timedelta(days=13), end - timedelta(days=7)
    sql = "SELECT id, nickname, created_at, group_id FROM users WHERE role='student' AND is_active=1"
    params = []
    if user_id is not None:
        sql += " AND id=?"
        params.append(user_id)
    students = con.execute(sql, params).fetchall()
    last = {r[0]: r[1] for r in con.execute(
        "SELECT user_id, MAX(day) FROM events WHERE event_type='answer' GROUP BY user_id")}
    cur = defaultdict(list)
    prev = defaultdict(list)
    for r in answer_rows(con, prev_start, end, user_id=user_id):
        (cur if d(r["day"]) >= cur_start else prev)[r["user_id"]].append(r)
    since14 = (today - timedelta(days=13)).isoformat()
    starts = dict(con.execute("SELECT user_id, COUNT(*) FROM events WHERE event_type='quiz_start' AND day>=? "
                              "GROUP BY user_id", (since14,)).fetchall())
    finishes = dict(con.execute("SELECT user_id, COUNT(*) FROM events WHERE event_type='quiz_complete' AND day>=? "
                                "GROUP BY user_id", (since14,)).fetchall())
    out = {}
    for s in students:
        uid, flags = s["id"], []
        la = last.get(uid)
        if la:
            gap = (today - d(la)).days
            if gap >= ABSENT_DAYS:
                flags.append(("absent", f"😴 не занимается {gap} дн.", f"absent:{la}"))
        elif (today - d(s["created_at"][:10])).days >= NEVER_DAYS:
            flags.append(("never", "😴 зарегистрировался(ась), но ни разу не занимался(ась)", "never"))
        n1, ok1 = totals(cur[uid])
        n0, ok0 = totals(prev[uid])
        if n1 >= MIN_ANSWERS and n0 >= MIN_ANSWERS and pct(ok1, n1) <= pct(ok0, n0) - DECLINE_POINTS:
            flags.append(("decline", f"📉 точность упала с {pct(ok0, n0)}% до {pct(ok1, n1)}%",
                          f"decline:{_iso_week(today)}"))
        overdue = [r[0] for r in con.execute(
            """SELECT h.id FROM homework h LEFT JOIN homework_status st ON st.homework_id=h.id AND st.user_id=?
               WHERE h.active=1 AND (h.group_id IS NULL OR h.group_id=?) AND h.due_date IS NOT NULL AND h.due_date<?
               AND COALESCE(st.status,'new') NOT IN ('done','submitted') ORDER BY h.id""",
            (uid, s["group_id"], today.isoformat()))]
        if len(overdue) >= OVERDUE_MIN:
            flags.append(("overdue", f"⏰ просрочено заданий: {len(overdue)}", "overdue:" + ",".join(map(str, overdue))))
        st_n, fin_n = starts.get(uid, 0), finishes.get(uid, 0)
        if st_n >= DROPOUT_MIN_STARTS and fin_n / st_n <= 0.5:
            flags.append(("dropout", f"🚪 бросает квизы: закончено {fin_n} из {st_n}", f"dropout:{_iso_week(today)}"))
        if flags:
            out[uid] = flags
    return out


def flags_text(flags):
    return "; ".join(f[1] for f in flags)


# =====================================================================================
#  Недельный дайджест
# =====================================================================================
def _arrow(now, before, unit="", points=False):
    if before is None or now is None:
        return ""
    diff = now - before
    if diff == 0:
        return " (без изменений)"
    sign = "▲ +" if diff > 0 else "▼ −"
    return f" ({sign}{abs(diff)}{' п.п.' if points else unit})"


def build_digest(con, today):
    """Текст дайджеста (HTML) за последние 7 завершённых дней и сравнение с предыдущими 7."""
    end = today - timedelta(days=1)
    cur_start, prev_start, prev_end = end - timedelta(days=6), end - timedelta(days=13), end - timedelta(days=7)
    students = con.execute("SELECT u.id, u.nickname, u.group_id, g.name AS grp FROM users u LEFT JOIN groups g "
                           "ON g.id=u.group_id WHERE u.role='student' AND u.is_active=1 "
                           "ORDER BY u.nickname COLLATE NOCASE").fetchall()
    head = f"📬 <b>Недельный дайджест</b> · {cur_start.strftime('%d.%m')}–{end.strftime('%d.%m')}"
    if not students:
        return head + "\n\nУчеников пока нет."
    cur_rows = answer_rows(con, cur_start, end)
    prev_rows = answer_rows(con, prev_start, prev_end)
    n1, ok1 = totals(cur_rows)
    n0, ok0 = totals(prev_rows)
    act1, act0 = {r["user_id"] for r in cur_rows}, {r["user_id"] for r in prev_rows}
    lines = [head, ""]
    if not n1:
        lines.append("На этой неделе никто не отвечал на вопросы.")
    else:
        lines += ["<b>Итоги недели</b>",
                  f"👥 Занимались: {len(act1)} из {len(students)}{_arrow(len(act1), len(act0) or None)}",
                  f"✍️ Ответов: {n1}{_arrow(n1, n0 or None)}",
                  f"🎯 Точность: {pct_text(ok1, n1)}{_arrow(pct(ok1, n1), pct(ok0, n0), points=True)}"]
    # по группам
    by_group = defaultdict(list)
    for s in students:
        by_group[s["grp"] or "Без группы"].append(s["id"])
    if len(by_group) > 1 or "Без группы" not in by_group:
        lines += ["", "<b>По группам</b>"]
        for name, ids in sorted(by_group.items()):
            rows = [r for r in cur_rows if r["user_id"] in ids]
            n, ok = totals(rows)
            lines.append(f"• {esc(name)} — занимались {len({r['user_id'] for r in rows})}/{len(ids)} · "
                         f"{pct_text(ok, n)} · {n} отв.")
    # слабые темы
    topics = defaultdict(lambda: [0, 0])
    for r in cur_rows:
        topics[r["topic"]][0] += 1
        topics[r["topic"]][1] += r["is_correct"] or 0
    weak = sorted(((pct(ok, n), t, n) for t, (n, ok) in topics.items() if n >= 10))[:3]
    weak = [w for w in weak if w[0] < 75]
    if weak:
        lines += ["", "<b>Что стоит разобрать на уроке</b>"]
        lines += [f"• {esc(t)}: {p}% ({n} отв.)" for p, t, n in weak]
    # внимание
    flags = risk_flags(con, today, end=end)
    if flags:
        names = {s["id"]: s["nickname"] for s in students}
        lines += ["", "<b>⚠️ Требуют внимания</b>"]
        lines += [f"• {esc(names[uid])} — {esc(flags_text(f))}" for uid, f in list(flags.items())[:12]]
        if len(flags) > 12:
            lines.append(f"…и ещё {len(flags) - 12}")
    # самые активные
    counts = defaultdict(int)
    for r in cur_rows:
        counts[r["user_id"]] += 1
    if counts:
        names = {s["id"]: s["nickname"] for s in students}
        top = sorted(counts.items(), key=lambda kv: -kv[1])[:3]
        lines += ["", "<b>🏆 Самые активные:</b> " + ", ".join(f"{esc(names[u])} ({c})" for u, c in top)]
    # домашка
    hw_lines = []
    for h in db.homework_active(con):
        prog = db.hw_progress(con, h)
        if not prog:
            continue
        done = sum(1 for p in prog if p["status"] == "done")
        waiting = sum(1 for p in prog if p["status"] == "submitted")
        title = esc(h["title"][:40])
        if h["due_date"] and h["due_date"] < today.isoformat():
            missing = [p["nickname"] for p in prog if p["status"] not in ("done", "submitted")]
            if missing:
                hw_lines.append(f"• ⚠️ «{title}» просрочено: не сделали {esc(', '.join(missing[:6]))}"
                                + ("…" if len(missing) > 6 else ""))
                continue
        hw_lines.append(f"• «{title}» ({'до ' + d(h['due_date']).strftime('%d.%m') if h['due_date'] else 'без срока'}): "
                        f"выполнили {done}/{len(prog)}" + (f", ждёт проверки: {waiting}" if waiting else ""))
    if hw_lines:
        lines += ["", "<b>📝 Домашние задания</b>"] + hw_lines[:8]
    # динамика
    dyn = weekly_lines(con, end)          # последняя строка — неделя, закончившаяся вчера
    if dyn:
        lines += ["", "<b>📈 Динамика (точность по неделям)</b>", "<pre>" + "\n".join(dyn) + "</pre>"]
    return "\n".join(lines)


# =====================================================================================
#  Экспорт в Excel
# =====================================================================================
HEADER_FONT = Font(name="Arial", size=10, bold=True, color="FFFFFF")
HEADER_FILL = PatternFill("solid", start_color="1F4E78")
BODY_FONT = Font(name="Arial", size=10)
GREEN, RED = PatternFill("solid", start_color="C6EFCE"), PatternFill("solid", start_color="FFC7CE")


def _sheet(wb, title, header, rows, widths=None, first=False):
    ws = wb.active if first else wb.create_sheet()
    ws.title = title
    ws.append(header)
    for r in rows:
        ws.append(list(r))
    for c in ws[1]:
        c.font, c.fill = HEADER_FONT, HEADER_FILL
        c.alignment = Alignment(wrap_text=True, vertical="center")
    for row in ws.iter_rows(min_row=2):
        for c in row:
            c.font = BODY_FONT
    for i, h in enumerate(header, 1):
        ws.column_dimensions[get_column_letter(i)].width = (widths or {}).get(i, max(11, min(34, len(str(h)) + 4)))
    ws.freeze_panes = "A2"
    if rows:
        ws.auto_filter.ref = ws.dimensions
    return ws


def build_export(con, today, path, weeks=8, log_days=180):
    """Собирает Excel-файл: ученики, темы по ученикам, динамика, журнал ответов, домашка."""
    since = today - timedelta(days=13)
    flags = risk_flags(con, today)
    students = db.students_overview(con, (today - timedelta(days=6)).isoformat())
    wb = Workbook()

    rows = []
    for s in students:
        uid = s["id"]
        ch = db.get_character(con, uid)
        tot = con.execute("SELECT COUNT(*), COALESCE(SUM(is_correct),0) FROM events WHERE user_id=? "
                          "AND event_type='answer'", (uid,)).fetchone()
        started, finished = db.quiz_counts(con, uid, since.isoformat())
        last = con.execute("SELECT MAX(day) FROM events WHERE user_id=? AND event_type='answer'", (uid,)).fetchone()[0]
        rows.append([s["nickname"], s["grp"] or "", ch["level"], db.cefr_for_level(ch["level"]), ch["xp"], ch["coins"],
                     db.effective_streak(ch, today), last or "", tot[0], pct(tot[1], tot[0]), s["n"],
                     pct(s["ok"], s["n"]), started, finished, flags_text(flags.get(uid, []))])
    ws = _sheet(wb, "Ученики", ["Ник", "Группа", "Уровень", "CEFR", "XP", "Монеты", "Серия, дн.", "Последний ответ",
                                "Ответов всего", "Точность всего, %", "Ответов за 7 дн.", "Точность за 7 дн., %",
                                "Квизов начато (14 дн.)", "Квизов закончено (14 дн.)", "Сигналы"], rows,
                {1: 18, 2: 18, 15: 48}, first=True)

    # темы × ученики
    topics = [r[0] for r in con.execute("SELECT DISTINCT topic FROM events WHERE event_type='answer' AND topic IS NOT NULL "
                                        "ORDER BY topic")]
    matrix = []
    for s in students:
        row = [s["nickname"], s["grp"] or ""]
        stat = {r["k"]: pct(r["ok"], r["n"]) for r in db.accuracy_by(con, s["id"], "topic")}
        row += [stat.get(t) for t in topics]
        matrix.append(row)
    ws = _sheet(wb, "Темы × ученики, %", ["Ник", "Группа"] + topics, matrix, {1: 18, 2: 18})
    for row in ws.iter_rows(min_row=2, min_col=3):
        for c in row:
            if isinstance(c.value, int) and (c.value >= 80 or c.value < 50):
                c.fill = GREEN if c.value >= 80 else RED

    # динамика
    first_week = monday(today) - timedelta(weeks=weeks - 1)
    week_starts = [first_week + timedelta(weeks=i) for i in range(weeks)]
    dyn = []
    for s in students:
        stats = {w["week"]: pct(w["ok"], w["n"]) for w in weekly_stats(con, today, weeks, user_id=s["id"])}
        dyn.append([s["nickname"], s["grp"] or ""] + [stats.get(w) for w in week_starts])
    total = {w["week"]: w for w in weekly_stats(con, today, weeks)}
    dyn.append(["ВСЕ", ""] + [pct(total[w]["ok"], total[w]["n"]) for w in week_starts])
    dyn.append(["Ответов (все)", ""] + [total[w]["n"] for w in week_starts])
    ws = _sheet(wb, "Динамика, %", ["Ник", "Группа"] + [f"нед. {w.strftime('%d.%m')}" for w in week_starts], dyn,
                {1: 18, 2: 18})
    for row in ws.iter_rows(min_row=2, max_row=1 + len(students), min_col=3):
        for c in row:
            if isinstance(c.value, int) and (c.value >= 80 or c.value < 50):
                c.fill = GREEN if c.value >= 80 else RED

    # журнал ответов
    log = con.execute(
        """SELECT e.day, u.nickname, g.name AS grp, e.topic, e.skill, e.cefr, e.question_id, e.is_correct,
                  e.response_time_ms, e.context FROM events e JOIN users u ON u.id=e.user_id
           LEFT JOIN groups g ON g.id=u.group_id WHERE e.event_type='answer' AND u.role='student' AND e.day>=?
           ORDER BY e.day, e.id LIMIT 50000""", ((today - timedelta(days=log_days)).isoformat(),)).fetchall()
    _sheet(wb, "Журнал ответов", ["Дата", "Ник", "Группа", "Тема", "Навык", "CEFR", "id вопроса", "Верно (1/0)",
                                  "Время, мс", "Откуда"], [tuple(r) for r in log], {1: 12, 2: 18, 3: 18, 4: 28})

    # домашка
    hw_rows = []
    for h in con.execute("SELECT * FROM homework ORDER BY id").fetchall():
        for p in db.hw_progress(con, h):
            hw_rows.append([h["id"], h["title"], "тест" if h["kind"] == "quiz" else "авторское",
                            db.group_name(con, h["group_id"]) or "все", h["due_date"] or "", "да" if h["active"] else "нет",
                            p["nickname"], p["status"] or "new", p["score"], p["total"], "да" if p["late"] else ""])
    _sheet(wb, "Домашка", ["№", "Задание", "Тип", "Группа", "Срок", "Активно", "Ученик", "Статус", "Балл", "Из",
                           "Опоздание"], hw_rows, {2: 30, 7: 18})
    wb.save(path)
    return path
