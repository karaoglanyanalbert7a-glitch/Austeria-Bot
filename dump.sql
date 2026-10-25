BEGIN TRANSACTION;
CREATE TABLE characters (
    user_id INTEGER PRIMARY KEY REFERENCES users(id),
    xp INTEGER NOT NULL DEFAULT 0, level INTEGER NOT NULL DEFAULT 1, coins INTEGER NOT NULL DEFAULT 0,
    vocabulary INTEGER NOT NULL DEFAULT 0, grammar INTEGER NOT NULL DEFAULT 0,
    listening INTEGER NOT NULL DEFAULT 0, speaking INTEGER NOT NULL DEFAULT 0,
    streak INTEGER NOT NULL DEFAULT 0, freezes INTEGER NOT NULL DEFAULT 1, last_active_date TEXT);
INSERT INTO "characters" VALUES(2,502,8,28,13,35,0,0,2,1,'2026-10-25');
INSERT INTO "characters" VALUES(3,553,8,25049,9,41,0,0,2,1,'2026-10-25');
INSERT INTO "characters" VALUES(4,2,1,0,0,0,0,0,0,1,NULL);
INSERT INTO "characters" VALUES(5,63,2,4,0,4,0,0,1,1,'2026-10-25');
INSERT INTO "characters" VALUES(6,0,1,0,0,0,0,0,0,1,NULL);
CREATE TABLE cheatsheets (
    id INTEGER PRIMARY KEY AUTOINCREMENT, topic TEXT UNIQUE NOT NULL, cefr TEXT, text TEXT NOT NULL);
INSERT INTO "cheatsheets" VALUES(1,'Basic verbs (be, have got, can)','A1','**to be (быть)**
I **am** · you/we/they **are** · he/she/it **is**
Отрицание: I am not · he isn''t · they aren''t
Вопрос: **Is** she at home? **Are** you ready?
There is + ед. число, there are + мн. число: There **are** three books on the table.
Прошедшее время: I/he/she/it **was**, you/we/they **were**.

**have got (иметь, владеть)**
I/you/we/they **have got** · he/she/it **has got**
Отрицание: haven''t got / hasn''t got
Вопрос: **Have** you got a car? **Has** she got a brother?

**can (уметь, мочь)**
Одна форма для всех лиц, без -s: she **can** swim.
Отрицание: can''t (cannot). Вопрос: **Can** you swim?
После can глагол без to: I can **speak** French.
Прошедшее время: could / couldn''t.');
INSERT INTO "cheatsheets" VALUES(2,'Present Simple','A1-A2','**Когда используем:** привычки, расписание, факты, постоянные состояния.
Слова-подсказки: always, usually, often, sometimes, never, every day.

**Утверждение:** I/you/we/they **work** · he/she/it **works**
Окончание -es после -s, -sh, -ch, -x, -o: watch → watch**es**, go → go**es**.
Согласная + y: study → stud**ies**.

**Отрицание:** I **don''t** work · he **doesn''t** work (глагол без -s!)
**Вопрос:** **Do** you work? **Does** she work? (глагол без -s!)
How often **do** you go to the gym?

**С глаголом to be** do/does не нужны: She **is** a teacher. **Is** she a teacher?
Наречия частоты стоят после to be, но перед обычным глаголом:
He **is** always late. He **always** comes late.

**Факты:** Water boils at 100 degrees.');
INSERT INTO "cheatsheets" VALUES(3,'Present Continuous','A1-A2','**Когда используем:** действие происходит прямо сейчас или в этот период; договорённости на ближайшее будущее.
Слова-подсказки: now, at the moment, today, this week, Look!

**Форма:** am / is / are + глагол с **-ing**
I **am** reading · she **is** reading · they **are** reading
Отрицание: She **isn''t** reading. Вопрос: **Are** you reading?

**Как писать -ing:**
make → mak**ing** (убираем -e)
run → ru**nn**ing (удваиваем согласную)
lie → lying

**Present Simple или Continuous?**
I usually **drink** coffee (привычка), but today I **am drinking** tea (сейчас).

**Глаголы состояния** обычно не используются в Continuous: know, like, love, want, understand, have (в значении «иметь»).
I **know** the answer. (не I am knowing)
Но: She **is having** a shower (принимает душ). Здесь have — действие.

**Будущее по договорённости:** I **am meeting** Tom tomorrow.');
INSERT INTO "cheatsheets" VALUES(4,'Past Simple','A1-A2','**Когда используем:** действие закончилось в прошлом.
Слова-подсказки: yesterday, last week, in 2020, two days ago.

**Правильные глаголы:** добавляем **-ed**
work → work**ed**, like → like**d**, study → stud**ied**, stop → stop**ped**

**Неправильные глаголы** нужно выучить:
go – went · buy – bought · see – saw · have – had · do – did · take – took · come – came

**Отрицание:** I **didn''t** go (после didn''t глагол в начальной форме!)
**Вопрос:** **Did** you go? (после did глагол в начальной форме)
Неверно: Did you went? Верно: Did you **go**?

**Глагол to be:** I/he/she/it **was**, you/we/they **were**.
Вопросы и отрицания без did: **Were** you at home? I **wasn''t** there.');
INSERT INTO "cheatsheets" VALUES(5,'Comparatives & Superlatives','A2','**Короткие прилагательные (1 слог):**
сравнительная степень **-er**, превосходная **the -est**
tall → tall**er** → the tall**est**
big → big**ger** → the big**gest** (удваиваем согласную)
nice → nic**er** → the nic**est**
happy → happ**ier** → the happ**iest** (y → i)

**Длинные прилагательные (2+ слога):** **more** / **the most**
interesting → **more** interesting → **the most** interesting
Наречия на -ly тоже с more: He drives **more carefully**.

**Исключения:**
good → better → the best
bad → worse → the worst
far → farther (further) → the farthest (furthest)

**Сравниваем:**
taller **than** me · as tall **as** me · not as tall as me

**The ... the ...:** The more you study, the better your results will be.');
CREATE TABLE events (
    id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL REFERENCES users(id),
    ts TEXT NOT NULL, day TEXT NOT NULL, event_type TEXT NOT NULL,
    question_id INTEGER, topic TEXT, skill TEXT, cefr TEXT, is_correct INTEGER,
    response_time_ms INTEGER, context TEXT, extra TEXT);
INSERT INTO "events" VALUES(1,1,'2026-10-24T19:28:13+00:00','2026-10-24','register',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(2,1,'2026-10-24T19:28:24+00:00','2026-10-24','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'daily',NULL);
INSERT INTO "events" VALUES(3,1,'2026-10-24T19:28:30+00:00','2026-10-24','answer',112,'Present Simple','grammar','A1',0,6236,'daily',NULL);
INSERT INTO "events" VALUES(4,1,'2026-10-24T19:28:43+00:00','2026-10-24','answer',105,'Basic verbs (be, have got, can)','grammar','A1',1,12531,'daily',NULL);
INSERT INTO "events" VALUES(5,1,'2026-10-24T19:28:48+00:00','2026-10-24','answer',121,'Present Continuous','grammar','A2',0,5359,'daily',NULL);
INSERT INTO "events" VALUES(6,1,'2026-10-24T19:28:51+00:00','2026-10-24','answer',101,'Basic verbs (be, have got, can)','grammar','A1',1,2132,'daily',NULL);
INSERT INTO "events" VALUES(7,1,'2026-10-24T19:28:54+00:00','2026-10-24','answer',115,'Present Simple','grammar','A2',1,3585,'daily',NULL);
INSERT INTO "events" VALUES(8,1,'2026-10-24T19:28:54+00:00','2026-10-24','quiz_complete',NULL,NULL,NULL,NULL,NULL,NULL,'daily','{"correct": 3, "total": 5}');
INSERT INTO "events" VALUES(9,1,'2026-10-24T19:29:09+00:00','2026-10-24','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(10,1,'2026-10-24T19:29:33+00:00','2026-10-24','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(11,1,'2026-10-24T19:29:45+00:00','2026-10-24','answer',108,'Basic verbs (be, have got, can)','grammar','A1',1,11886,'practice',NULL);
INSERT INTO "events" VALUES(12,1,'2026-10-24T19:29:48+00:00','2026-10-24','answer',110,'Present Simple','grammar','A1',1,3368,'practice',NULL);
INSERT INTO "events" VALUES(13,1,'2026-10-24T19:29:55+00:00','2026-10-24','answer',106,'Basic verbs (be, have got, can)','grammar','A1',1,6505,'practice',NULL);
INSERT INTO "events" VALUES(14,1,'2026-10-24T19:30:01+00:00','2026-10-24','answer',131,'Past Simple','grammar','A2',1,5751,'practice',NULL);
INSERT INTO "events" VALUES(15,1,'2026-10-24T19:30:06+00:00','2026-10-24','answer',118,'Present Continuous','grammar','A1',0,5149,'practice',NULL);
INSERT INTO "events" VALUES(16,1,'2026-10-24T19:30:06+00:00','2026-10-24','quiz_complete',NULL,NULL,NULL,NULL,NULL,NULL,'practice','{"correct": 4, "total": 5}');
INSERT INTO "events" VALUES(17,2,'2026-10-24T19:32:47+00:00','2026-10-24','register',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(18,2,'2026-10-24T19:32:51+00:00','2026-10-24','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'daily',NULL);
INSERT INTO "events" VALUES(19,2,'2026-10-24T19:32:58+00:00','2026-10-24','answer',127,'Past Simple','grammar','A1',1,7023,'daily',NULL);
INSERT INTO "events" VALUES(20,2,'2026-10-24T19:33:21+00:00','2026-10-24','answer',136,'Comparatives & Superlatives','grammar','A2',1,22446,'daily',NULL);
INSERT INTO "events" VALUES(21,2,'2026-10-24T19:33:28+00:00','2026-10-24','answer',114,'Present Simple','grammar','A2',1,7147,'daily',NULL);
INSERT INTO "events" VALUES(22,2,'2026-10-24T19:33:33+00:00','2026-10-24','answer',118,'Present Continuous','grammar','A1',1,4335,'daily',NULL);
INSERT INTO "events" VALUES(23,2,'2026-10-24T19:33:39+00:00','2026-10-24','answer',125,'Past Simple','grammar','A1',1,6281,'daily',NULL);
INSERT INTO "events" VALUES(24,2,'2026-10-24T19:33:39+00:00','2026-10-24','quiz_complete',NULL,NULL,NULL,NULL,NULL,NULL,'daily','{"correct": 5, "total": 5}');
INSERT INTO "events" VALUES(25,3,'2026-10-24T19:35:08+00:00','2026-10-24','register',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(26,3,'2026-10-24T19:35:12+00:00','2026-10-24','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'daily',NULL);
INSERT INTO "events" VALUES(27,3,'2026-10-24T19:35:15+00:00','2026-10-24','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(28,3,'2026-10-24T19:35:15+00:00','2026-10-24','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(29,3,'2026-10-24T19:35:30+00:00','2026-10-24','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(30,3,'2026-10-24T19:35:33+00:00','2026-10-24','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(31,3,'2026-10-24T19:36:05+00:00','2026-10-24','answer',135,'Comparatives & Superlatives','grammar','A2',1,31900,'practice',NULL);
INSERT INTO "events" VALUES(32,3,'2026-10-24T19:36:38+00:00','2026-10-24','answer',138,'Comparatives & Superlatives','grammar','A2',0,32877,'practice',NULL);
INSERT INTO "events" VALUES(33,3,'2026-10-24T19:36:50+00:00','2026-10-24','answer',134,'Comparatives & Superlatives','grammar','A2',1,12416,'practice',NULL);
INSERT INTO "events" VALUES(34,3,'2026-10-24T19:37:31+00:00','2026-10-24','answer',139,'Comparatives & Superlatives','grammar','A2',0,40323,'practice',NULL);
INSERT INTO "events" VALUES(35,3,'2026-10-24T19:37:43+00:00','2026-10-24','answer',128,'Past Simple','grammar','A2',1,12020,'practice',NULL);
INSERT INTO "events" VALUES(36,3,'2026-10-24T19:37:43+00:00','2026-10-24','quiz_complete',NULL,NULL,NULL,NULL,NULL,NULL,'practice','{"correct": 3, "total": 5}');
INSERT INTO "events" VALUES(37,1,'2026-10-24T19:46:34+00:00','2026-10-24','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(38,1,'2026-10-24T19:46:40+00:00','2026-10-24','answer',136,'Comparatives & Superlatives','grammar','A2',1,5835,'practice',NULL);
INSERT INTO "events" VALUES(39,1,'2026-10-24T19:46:43+00:00','2026-10-24','answer',103,'Basic verbs (be, have got, can)','grammar','A1',0,2816,'practice',NULL);
INSERT INTO "events" VALUES(40,1,'2026-10-24T19:46:46+00:00','2026-10-24','answer',123,'Present Continuous','grammar','A2',0,2053,'practice',NULL);
INSERT INTO "events" VALUES(41,1,'2026-10-24T19:46:57+00:00','2026-10-24','answer',114,'Present Simple','grammar','A2',1,11190,'practice',NULL);
INSERT INTO "events" VALUES(42,1,'2026-10-24T19:47:00+00:00','2026-10-24','answer',133,'Comparatives & Superlatives','grammar','A2',0,2881,'practice',NULL);
INSERT INTO "events" VALUES(43,1,'2026-10-24T19:47:00+00:00','2026-10-24','quiz_complete',NULL,NULL,NULL,NULL,NULL,NULL,'practice','{"correct": 2, "total": 5}');
INSERT INTO "events" VALUES(44,1,'2026-10-24T19:47:04+00:00','2026-10-24','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(45,1,'2026-10-24T19:47:04+00:00','2026-10-24','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(46,1,'2026-10-24T19:47:04+00:00','2026-10-24','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(47,1,'2026-10-24T19:47:05+00:00','2026-10-24','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(48,1,'2026-10-24T19:47:12+00:00','2026-10-24','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(49,3,'2026-10-24T20:02:10+00:00','2026-10-24','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(50,1,'2026-10-24T20:02:16+00:00','2026-10-24','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(51,1,'2026-10-24T20:06:55+00:00','2026-10-24','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(52,1,'2026-10-24T20:06:57+00:00','2026-10-24','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(53,1,'2026-10-24T20:07:06+00:00','2026-10-24','answer',126,'Past Simple','grammar','A1',1,8964,'practice',NULL);
INSERT INTO "events" VALUES(54,1,'2026-10-24T20:07:10+00:00','2026-10-24','answer',116,'Present Simple','grammar','A2',0,4094,'practice',NULL);
INSERT INTO "events" VALUES(55,1,'2026-10-24T20:07:12+00:00','2026-10-24','answer',138,'Comparatives & Superlatives','grammar','A2',0,1890,'practice',NULL);
INSERT INTO "events" VALUES(56,1,'2026-10-24T20:07:15+00:00','2026-10-24','answer',127,'Past Simple','grammar','A1',1,2942,'practice',NULL);
INSERT INTO "events" VALUES(57,1,'2026-10-24T20:07:20+00:00','2026-10-24','answer',139,'Comparatives & Superlatives','grammar','A2',1,4395,'practice',NULL);
INSERT INTO "events" VALUES(58,1,'2026-10-24T20:07:20+00:00','2026-10-24','quiz_complete',NULL,NULL,NULL,NULL,NULL,NULL,'practice','{"correct": 3, "total": 5}');
INSERT INTO "events" VALUES(59,1,'2026-10-25T00:17:07+00:00','2026-10-25','cheatsheet_view',NULL,'Basic verbs (be, have got, can)',NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(60,1,'2026-10-25T00:17:59+00:00','2026-10-25','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(61,1,'2026-10-25T00:21:36+00:00','2026-10-25','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'daily',NULL);
INSERT INTO "events" VALUES(62,1,'2026-10-25T00:21:45+00:00','2026-10-25','answer',111,'Present Simple','grammar','A1',0,9378,'daily',NULL);
INSERT INTO "events" VALUES(63,1,'2026-10-25T00:21:50+00:00','2026-10-25','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(64,1,'2026-10-25T00:21:55+00:00','2026-10-25','answer',104,'Basic verbs (be, have got, can)','grammar','A1',0,3197,'daily',NULL);
INSERT INTO "events" VALUES(65,1,'2026-10-25T00:21:56+00:00','2026-10-25','answer',134,'Comparatives & Superlatives','grammar','A2',0,981,'daily',NULL);
INSERT INTO "events" VALUES(66,1,'2026-10-25T00:21:58+00:00','2026-10-25','answer',132,'Past Simple','grammar','A2',1,1082,'daily',NULL);
INSERT INTO "events" VALUES(67,1,'2026-10-25T00:25:05+00:00','2026-10-25','answer',120,'Present Continuous','grammar','A1',1,186886,'daily',NULL);
INSERT INTO "events" VALUES(68,1,'2026-10-25T00:25:05+00:00','2026-10-25','quiz_complete',NULL,NULL,NULL,NULL,NULL,NULL,'daily','{"correct": 2, "total": 5}');
INSERT INTO "events" VALUES(69,1,'2026-10-25T00:25:14+00:00','2026-10-25','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(70,1,'2026-10-25T00:35:46+00:00','2026-10-25','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(71,1,'2026-10-25T00:35:51+00:00','2026-10-25','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(72,2,'2026-10-25T09:56:47+00:00','2026-10-25','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'daily',NULL);
INSERT INTO "events" VALUES(73,2,'2026-10-25T09:56:47+00:00','2026-10-25','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(74,2,'2026-10-25T10:00:14+00:00','2026-10-25','hw_start',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 2}');
INSERT INTO "events" VALUES(75,2,'2026-10-25T10:00:23+00:00','2026-10-25','answer',127,'Past Simple','grammar','A1',1,9271,'homework',NULL);
INSERT INTO "events" VALUES(76,2,'2026-10-25T10:00:28+00:00','2026-10-25','answer',109,'Present Simple','grammar','A1',1,2996,'homework',NULL);
INSERT INTO "events" VALUES(77,2,'2026-10-25T10:00:31+00:00','2026-10-25','answer',101,'Basic verbs (be, have got, can)','grammar','A1',1,2361,'homework',NULL);
INSERT INTO "events" VALUES(78,2,'2026-10-25T10:00:41+00:00','2026-10-25','answer',121,'Present Continuous','grammar','A2',1,9050,'homework',NULL);
INSERT INTO "events" VALUES(79,2,'2026-10-25T10:00:50+00:00','2026-10-25','answer',128,'Past Simple','grammar','A2',1,7880,'homework',NULL);
INSERT INTO "events" VALUES(80,2,'2026-10-25T10:00:56+00:00','2026-10-25','answer',136,'Comparatives & Superlatives','grammar','A2',1,5369,'homework',NULL);
INSERT INTO "events" VALUES(81,2,'2026-10-25T10:01:02+00:00','2026-10-25','answer',114,'Present Simple','grammar','A2',1,3985,'homework',NULL);
INSERT INTO "events" VALUES(82,2,'2026-10-25T10:01:15+00:00','2026-10-25','answer',116,'Present Simple','grammar','A2',1,11448,'homework',NULL);
INSERT INTO "events" VALUES(83,2,'2026-10-25T10:01:23+00:00','2026-10-25','answer',124,'Present Continuous','grammar','B1',0,6965,'homework',NULL);
INSERT INTO "events" VALUES(84,2,'2026-10-25T10:01:34+00:00','2026-10-25','answer',140,'Comparatives & Superlatives','grammar','B1',1,9645,'homework',NULL);
INSERT INTO "events" VALUES(85,2,'2026-10-25T10:01:34+00:00','2026-10-25','hw_complete',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 2, "correct": 9, "total": 10}');
INSERT INTO "events" VALUES(86,2,'2026-10-25T10:01:34+00:00','2026-10-25','reward',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "xp", "amount": 10, "reason": "Бонус за домашку в срок"}');
INSERT INTO "events" VALUES(87,2,'2026-10-25T10:01:37+00:00','2026-10-25','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(88,2,'2026-10-25T10:01:41+00:00','2026-10-25','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(89,2,'2026-10-25T10:01:52+00:00','2026-10-25','cheatsheet_view',NULL,'Comparatives & Superlatives',NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(90,2,'2026-10-25T10:01:55+00:00','2026-10-25','cheatsheet_view',NULL,'Present Simple',NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(91,2,'2026-10-25T10:01:58+00:00','2026-10-25','cheatsheet_view',NULL,'Basic verbs (be, have got, can)',NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(92,2,'2026-10-25T10:02:01+00:00','2026-10-25','cheatsheet_view',NULL,'Present Continuous',NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(93,2,'2026-10-25T10:02:09+00:00','2026-10-25','cheatsheet_view',NULL,'Past Simple',NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(94,2,'2026-10-25T10:02:13+00:00','2026-10-25','cheatsheet_view',NULL,'Basic verbs (be, have got, can)',NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(95,2,'2026-10-25T10:02:15+00:00','2026-10-25','cheatsheet_view',NULL,'Comparatives & Superlatives',NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(96,3,'2026-10-25T10:13:35+00:00','2026-10-25','hw_start',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 2}');
INSERT INTO "events" VALUES(97,3,'2026-10-25T10:13:48+00:00','2026-10-25','answer',127,'Past Simple','grammar','A1',1,13285,'homework',NULL);
INSERT INTO "events" VALUES(98,3,'2026-10-25T10:13:57+00:00','2026-10-25','answer',109,'Present Simple','grammar','A1',1,7003,'homework',NULL);
INSERT INTO "events" VALUES(99,3,'2026-10-25T10:14:05+00:00','2026-10-25','answer',101,'Basic verbs (be, have got, can)','grammar','A1',1,5020,'homework',NULL);
INSERT INTO "events" VALUES(100,4,'2026-10-25T10:14:12+00:00','2026-10-25','register',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(101,3,'2026-10-25T10:14:13+00:00','2026-10-25','answer',121,'Present Continuous','grammar','A2',0,6456,'homework',NULL);
INSERT INTO "events" VALUES(102,4,'2026-10-25T10:14:25+00:00','2026-10-25','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'daily',NULL);
INSERT INTO "events" VALUES(103,4,'2026-10-25T10:14:31+00:00','2026-10-25','answer',137,'Comparatives & Superlatives','grammar','A2',0,6245,'daily',NULL);
INSERT INTO "events" VALUES(104,3,'2026-10-25T10:14:36+00:00','2026-10-25','answer',128,'Past Simple','grammar','A2',1,13592,'homework',NULL);
INSERT INTO "events" VALUES(105,3,'2026-10-25T10:15:23+00:00','2026-10-25','answer',136,'Comparatives & Superlatives','grammar','A2',1,44789,'homework',NULL);
INSERT INTO "events" VALUES(106,4,'2026-10-25T10:15:39+00:00','2026-10-25','cheatsheet_view',NULL,'Present Simple',NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(107,3,'2026-10-25T10:15:46+00:00','2026-10-25','answer',114,'Present Simple','grammar','A2',1,15943,'homework',NULL);
INSERT INTO "events" VALUES(108,3,'2026-10-25T10:16:06+00:00','2026-10-25','answer',116,'Present Simple','grammar','A2',1,16985,'homework',NULL);
INSERT INTO "events" VALUES(109,3,'2026-10-25T10:16:44+00:00','2026-10-25','answer',124,'Present Continuous','grammar','B1',0,36073,'homework',NULL);
INSERT INTO "events" VALUES(110,3,'2026-10-25T10:16:49+00:00','2026-10-25','cheatsheet_view',NULL,'Present Continuous',NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(111,3,'2026-10-25T10:17:43+00:00','2026-10-25','answer',140,'Comparatives & Superlatives','grammar','B1',1,17299,'homework',NULL);
INSERT INTO "events" VALUES(112,3,'2026-10-25T10:17:43+00:00','2026-10-25','hw_complete',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 2, "correct": 8, "total": 10}');
INSERT INTO "events" VALUES(113,3,'2026-10-25T10:17:43+00:00','2026-10-25','reward',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "xp", "amount": 10, "reason": "Бонус за домашку в срок"}');
INSERT INTO "events" VALUES(114,3,'2026-10-25T10:22:43+00:00','2026-10-25','reward',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "coins", "amount": 25000, "reason": "[Потому что ты самый сладкий пирожёк)))]"}');
INSERT INTO "events" VALUES(115,2,'2026-10-25T10:25:00+00:00','2026-10-25','reward',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "coins", "amount": 25000, "reason": "[Ты соска]"}');
INSERT INTO "events" VALUES(116,2,'2026-10-25T10:25:43+00:00','2026-10-25','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(117,2,'2026-10-25T10:25:47+00:00','2026-10-25','answer',102,'Basic verbs (be, have got, can)','grammar','A1',1,4224,'practice',NULL);
INSERT INTO "events" VALUES(118,2,'2026-10-25T10:25:53+00:00','2026-10-25','answer',135,'Comparatives & Superlatives','grammar','A2',1,4936,'practice',NULL);
INSERT INTO "events" VALUES(119,2,'2026-10-25T10:26:16+00:00','2026-10-25','answer',103,'Basic verbs (be, have got, can)','grammar','A1',1,21370,'practice',NULL);
INSERT INTO "events" VALUES(120,2,'2026-10-25T10:26:25+00:00','2026-10-25','answer',107,'Basic verbs (be, have got, can)','grammar','A2',1,8242,'practice',NULL);
INSERT INTO "events" VALUES(121,2,'2026-10-25T10:26:29+00:00','2026-10-25','answer',113,'Present Simple','grammar','A2',1,3219,'practice',NULL);
INSERT INTO "events" VALUES(122,2,'2026-10-25T10:26:29+00:00','2026-10-25','quiz_complete',NULL,NULL,NULL,NULL,NULL,NULL,'practice','{"correct": 5, "total": 5}');
INSERT INTO "events" VALUES(123,2,'2026-10-25T10:26:36+00:00','2026-10-25','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(124,2,'2026-10-25T10:26:41+00:00','2026-10-25','answer',137,'Comparatives & Superlatives','grammar','A2',1,4962,'practice',NULL);
INSERT INTO "events" VALUES(125,2,'2026-10-25T10:26:45+00:00','2026-10-25','answer',110,'Present Simple','grammar','A1',1,3062,'practice',NULL);
INSERT INTO "events" VALUES(126,2,'2026-10-25T10:26:53+00:00','2026-10-25','answer',105,'Basic verbs (be, have got, can)','grammar','A1',1,6069,'practice',NULL);
INSERT INTO "events" VALUES(127,2,'2026-10-25T10:26:54+00:00','2026-10-25','penalty',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "coins", "amount": -25013, "reason": "Ты вдвойне сосок"}');
INSERT INTO "events" VALUES(128,3,'2026-10-25T10:34:35+00:00','2026-10-25','hw_start',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 3}');
INSERT INTO "events" VALUES(129,3,'2026-10-25T10:34:56+00:00','2026-10-25','answer',120,'Present Continuous','grammar','A1',1,21273,'homework',NULL);
INSERT INTO "events" VALUES(130,3,'2026-10-25T10:35:13+00:00','2026-10-25','answer',103,'Basic verbs (be, have got, can)','grammar','A1',1,13962,'homework',NULL);
INSERT INTO "events" VALUES(131,3,'2026-10-25T10:35:23+00:00','2026-10-25','answer',105,'Basic verbs (be, have got, can)','grammar','A1',1,8819,'homework',NULL);
INSERT INTO "events" VALUES(132,3,'2026-10-25T10:35:31+00:00','2026-10-25','answer',101,'Basic verbs (be, have got, can)','grammar','A1',1,6003,'homework',NULL);
INSERT INTO "events" VALUES(133,3,'2026-10-25T10:35:53+00:00','2026-10-25','answer',108,'Basic verbs (be, have got, can)','grammar','A1',1,20723,'homework',NULL);
INSERT INTO "events" VALUES(134,3,'2026-10-25T10:36:06+00:00','2026-10-25','answer',126,'Past Simple','grammar','A1',1,7893,'homework',NULL);
INSERT INTO "events" VALUES(135,3,'2026-10-25T10:36:14+00:00','2026-10-25','answer',125,'Past Simple','grammar','A1',1,6169,'homework',NULL);
INSERT INTO "events" VALUES(136,2,'2026-10-25T10:37:16+00:00','2026-10-25','hw_start',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 4}');
INSERT INTO "events" VALUES(137,2,'2026-10-25T10:37:26+00:00','2026-10-25','answer',340,'Jobs & workplaces','vocabulary','A1',1,9817,'homework',NULL);
INSERT INTO "events" VALUES(138,2,'2026-10-25T10:37:33+00:00','2026-10-25','answer',125,'Past Simple','grammar','A1',1,4840,'homework',NULL);
INSERT INTO "events" VALUES(139,2,'2026-10-25T10:37:41+00:00','2026-10-25','answer',332,'Body & health','vocabulary','A1',1,7046,'homework',NULL);
INSERT INTO "events" VALUES(140,2,'2026-10-25T10:37:45+00:00','2026-10-25','answer',189,'Imperatives & suggestions (let''s)','grammar','A1',1,3265,'homework',NULL);
INSERT INTO "events" VALUES(141,2,'2026-10-25T10:37:50+00:00','2026-10-25','answer',149,'Plurals & countable/uncountable nouns','grammar','A1',1,2986,'homework',NULL);
INSERT INTO "events" VALUES(142,2,'2026-10-25T10:37:54+00:00','2026-10-25','answer',326,'Animals & nature','vocabulary','A1',1,3704,'homework',NULL);
INSERT INTO "events" VALUES(143,3,'2026-10-25T10:38:00+00:00','2026-10-25','answer',119,'Present Continuous','grammar','A1',1,104715,'homework',NULL);
INSERT INTO "events" VALUES(144,2,'2026-10-25T10:38:09+00:00','2026-10-25','answer',200,'Prepositions of place & movement','grammar','A1',1,13823,'homework',NULL);
INSERT INTO "events" VALUES(145,2,'2026-10-25T10:38:15+00:00','2026-10-25','answer',357,'Travel & transport','vocabulary','A1',1,4724,'homework',NULL);
INSERT INTO "events" VALUES(146,3,'2026-10-25T10:38:18+00:00','2026-10-25','answer',104,'Basic verbs (be, have got, can)','grammar','A1',1,14460,'homework',NULL);
INSERT INTO "events" VALUES(147,2,'2026-10-25T10:38:23+00:00','2026-10-25','answer',280,'Family & friends','vocabulary','A1',1,7151,'homework',NULL);
INSERT INTO "events" VALUES(148,2,'2026-10-25T10:38:31+00:00','2026-10-25','answer',188,'Question words & question forms','grammar','A2',1,7108,'homework',NULL);
INSERT INTO "events" VALUES(149,3,'2026-10-25T10:38:37+00:00','2026-10-25','answer',117,'Present Continuous','grammar','A1',1,17213,'homework',NULL);
INSERT INTO "events" VALUES(150,2,'2026-10-25T10:38:40+00:00','2026-10-25','answer',237,'Past Continuous','grammar','A2',1,7381,'homework',NULL);
INSERT INTO "events" VALUES(151,2,'2026-10-25T10:38:45+00:00','2026-10-25','answer',122,'Present Continuous','grammar','A2',1,3988,'homework',NULL);
INSERT INTO "events" VALUES(152,3,'2026-10-25T10:38:46+00:00','2026-10-25','answer',109,'Present Simple','grammar','A1',1,5663,'homework',NULL);
INSERT INTO "events" VALUES(153,2,'2026-10-25T10:38:57+00:00','2026-10-25','answer',220,'Adverbs (frequency, manner)','grammar','A2',1,11210,'homework',NULL);
INSERT INTO "events" VALUES(154,3,'2026-10-25T10:39:01+00:00','2026-10-25','answer',106,'Basic verbs (be, have got, can)','grammar','A1',1,13777,'homework',NULL);
INSERT INTO "events" VALUES(155,2,'2026-10-25T10:39:04+00:00','2026-10-25','answer',371,'Technology & communication','vocabulary','A2',1,5545,'homework',NULL);
INSERT INTO "events" VALUES(156,3,'2026-10-25T10:39:09+00:00','2026-10-25','answer',110,'Present Simple','grammar','A1',1,6138,'homework',NULL);
INSERT INTO "events" VALUES(157,2,'2026-10-25T10:39:11+00:00','2026-10-25','answer',324,'Weather & seasons','vocabulary','A2',1,5529,'homework',NULL);
INSERT INTO "events" VALUES(158,3,'2026-10-25T10:39:20+00:00','2026-10-25','answer',107,'Basic verbs (be, have got, can)','grammar','A2',1,10254,'homework',NULL);
INSERT INTO "events" VALUES(159,2,'2026-10-25T10:39:23+00:00','2026-10-25','answer',268,'Conditionals (zero & first)','grammar','A2',0,11539,'homework',NULL);
INSERT INTO "events" VALUES(160,3,'2026-10-25T10:39:36+00:00','2026-10-25','answer',128,'Past Simple','grammar','A2',1,12196,'homework',NULL);
INSERT INTO "events" VALUES(161,3,'2026-10-25T10:39:46+00:00','2026-10-25','answer',138,'Comparatives & Superlatives','grammar','A2',1,7782,'homework',NULL);
INSERT INTO "events" VALUES(162,2,'2026-10-25T10:39:55+00:00','2026-10-25','answer',265,'Conditionals (zero & first)','grammar','A2',1,15806,'homework',NULL);
INSERT INTO "events" VALUES(163,3,'2026-10-25T10:39:56+00:00','2026-10-25','answer',137,'Comparatives & Superlatives','grammar','A2',1,8865,'homework',NULL);
INSERT INTO "events" VALUES(164,3,'2026-10-25T10:40:16+00:00','2026-10-25','answer',131,'Past Simple','grammar','A2',1,17727,'homework',NULL);
INSERT INTO "events" VALUES(165,2,'2026-10-25T10:40:17+00:00','2026-10-25','answer',398,'Jobs & workplaces','reading','A2',0,21009,'homework',NULL);
INSERT INTO "events" VALUES(166,2,'2026-10-25T10:40:43+00:00','2026-10-25','answer',393,'Food & drink','reading','A2',1,24984,'homework',NULL);
INSERT INTO "events" VALUES(167,3,'2026-10-25T10:40:49+00:00','2026-10-25','answer',139,'Comparatives & Superlatives','grammar','A2',1,23306,'homework',NULL);
INSERT INTO "events" VALUES(168,3,'2026-10-25T10:41:03+00:00','2026-10-25','answer',136,'Comparatives & Superlatives','grammar','A2',1,7869,'homework',NULL);
INSERT INTO "events" VALUES(169,3,'2026-10-25T10:41:03+00:00','2026-10-25','hw_complete',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 3, "correct": 20, "total": 20}');
INSERT INTO "events" VALUES(170,3,'2026-10-25T10:41:03+00:00','2026-10-25','reward',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "xp", "amount": 10, "reason": "Бонус за домашку в срок"}');
INSERT INTO "events" VALUES(171,3,'2026-10-25T10:41:22+00:00','2026-10-25','hw_start',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 4}');
INSERT INTO "events" VALUES(172,3,'2026-10-25T10:41:42+00:00','2026-10-25','answer',340,'Jobs & workplaces','vocabulary','A1',1,20135,'homework',NULL);
INSERT INTO "events" VALUES(173,3,'2026-10-25T10:41:52+00:00','2026-10-25','answer',125,'Past Simple','grammar','A1',1,5861,'homework',NULL);
INSERT INTO "events" VALUES(174,3,'2026-10-25T10:42:06+00:00','2026-10-25','answer',332,'Body & health','vocabulary','A1',1,11316,'homework',NULL);
INSERT INTO "events" VALUES(175,3,'2026-10-25T10:42:16+00:00','2026-10-25','answer',189,'Imperatives & suggestions (let''s)','grammar','A1',1,9293,'homework',NULL);
INSERT INTO "events" VALUES(176,3,'2026-10-25T10:42:30+00:00','2026-10-25','answer',149,'Plurals & countable/uncountable nouns','grammar','A1',1,11466,'homework',NULL);
INSERT INTO "events" VALUES(177,3,'2026-10-25T10:42:37+00:00','2026-10-25','answer',326,'Animals & nature','vocabulary','A1',1,4314,'homework',NULL);
INSERT INTO "events" VALUES(178,3,'2026-10-25T10:42:46+00:00','2026-10-25','answer',200,'Prepositions of place & movement','grammar','A1',1,7878,'homework',NULL);
INSERT INTO "events" VALUES(179,3,'2026-10-25T10:43:01+00:00','2026-10-25','answer',357,'Travel & transport','vocabulary','A1',1,12071,'homework',NULL);
INSERT INTO "events" VALUES(180,2,'2026-10-25T10:43:04+00:00','2026-10-25','answer',107,'Basic verbs (be, have got, can)','grammar','A2',1,139790,'homework',NULL);
INSERT INTO "events" VALUES(181,2,'2026-10-25T10:43:05+00:00','2026-10-25','hw_complete',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 4, "correct": 18, "total": 20}');
INSERT INTO "events" VALUES(182,2,'2026-10-25T10:43:05+00:00','2026-10-25','reward',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "xp", "amount": 10, "reason": "Бонус за домашку в срок"}');
INSERT INTO "events" VALUES(183,3,'2026-10-25T10:43:09+00:00','2026-10-25','answer',280,'Family & friends','vocabulary','A1',1,6165,'homework',NULL);
INSERT INTO "events" VALUES(184,3,'2026-10-25T10:43:20+00:00','2026-10-25','answer',188,'Question words & question forms','grammar','A2',1,9166,'homework',NULL);
INSERT INTO "events" VALUES(185,3,'2026-10-25T10:43:59+00:00','2026-10-25','answer',237,'Past Continuous','grammar','A2',1,36962,'homework',NULL);
INSERT INTO "events" VALUES(186,3,'2026-10-25T10:44:22+00:00','2026-10-25','answer',122,'Present Continuous','grammar','A2',1,13693,'homework',NULL);
INSERT INTO "events" VALUES(187,3,'2026-10-25T10:44:51+00:00','2026-10-25','answer',220,'Adverbs (frequency, manner)','grammar','A2',0,23685,'homework',NULL);
INSERT INTO "events" VALUES(188,3,'2026-10-25T10:45:15+00:00','2026-10-25','answer',371,'Technology & communication','vocabulary','A2',1,19556,'homework',NULL);
INSERT INTO "events" VALUES(189,3,'2026-10-25T10:45:47+00:00','2026-10-25','answer',324,'Weather & seasons','vocabulary','A2',1,28050,'homework',NULL);
INSERT INTO "events" VALUES(190,3,'2026-10-25T10:46:23+00:00','2026-10-25','answer',268,'Conditionals (zero & first)','grammar','A2',1,34223,'homework',NULL);
INSERT INTO "events" VALUES(191,3,'2026-10-25T10:46:51+00:00','2026-10-25','answer',265,'Conditionals (zero & first)','grammar','A2',1,24280,'homework',NULL);
INSERT INTO "events" VALUES(192,3,'2026-10-25T10:47:38+00:00','2026-10-25','answer',398,'Jobs & workplaces','reading','A2',1,44056,'homework',NULL);
INSERT INTO "events" VALUES(193,3,'2026-10-25T10:48:06+00:00','2026-10-25','answer',393,'Food & drink','reading','A2',1,24107,'homework',NULL);
INSERT INTO "events" VALUES(194,3,'2026-10-25T10:48:21+00:00','2026-10-25','answer',107,'Basic verbs (be, have got, can)','grammar','A2',1,10738,'homework',NULL);
INSERT INTO "events" VALUES(195,3,'2026-10-25T10:48:21+00:00','2026-10-25','hw_complete',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 4, "correct": 19, "total": 20}');
INSERT INTO "events" VALUES(196,3,'2026-10-25T10:48:21+00:00','2026-10-25','reward',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "xp", "amount": 10, "reason": "Бонус за домашку в срок"}');
INSERT INTO "events" VALUES(197,2,'2026-10-25T11:51:30+00:00','2026-10-25','hw_start',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 5}');
INSERT INTO "events" VALUES(198,2,'2026-10-25T11:51:32+00:00','2026-10-25','answer',387,'Hobbies & sport','reading','A1',0,1684,'homework',NULL);
INSERT INTO "events" VALUES(199,2,'2026-10-25T11:51:36+00:00','2026-10-25','answer',298,'Clothes & colours','vocabulary','A1',0,3073,'homework',NULL);
INSERT INTO "events" VALUES(200,2,'2026-10-25T11:51:38+00:00','2026-10-25','answer',253,'Future (will, going to)','grammar','A1',0,1164,'homework',NULL);
INSERT INTO "events" VALUES(201,2,'2026-10-25T11:51:41+00:00','2026-10-25','answer',182,'Question words & question forms','grammar','A1',0,999,'homework',NULL);
INSERT INTO "events" VALUES(202,2,'2026-10-25T11:51:44+00:00','2026-10-25','answer',207,'Prepositions of time (in/on/at)','grammar','A1',0,2227,'homework',NULL);
INSERT INTO "events" VALUES(203,2,'2026-10-25T11:51:46+00:00','2026-10-25','answer',238,'Past Continuous','grammar','A2',0,933,'homework',NULL);
INSERT INTO "events" VALUES(204,2,'2026-10-25T11:51:48+00:00','2026-10-25','answer',265,'Conditionals (zero & first)','grammar','A2',1,910,'homework',NULL);
INSERT INTO "events" VALUES(205,2,'2026-10-25T11:51:52+00:00','2026-10-25','answer',260,'Future (will, going to)','grammar','A2',0,2569,'homework',NULL);
INSERT INTO "events" VALUES(206,2,'2026-10-25T11:51:54+00:00','2026-10-25','answer',254,'Future (will, going to)','grammar','A2',0,1066,'homework',NULL);
INSERT INTO "events" VALUES(207,2,'2026-10-25T11:51:57+00:00','2026-10-25','answer',179,'There is / There are','grammar','A2',0,1061,'homework',NULL);
INSERT INTO "events" VALUES(208,2,'2026-10-25T11:51:58+00:00','2026-10-25','answer',195,'Imperatives & suggestions (let''s)','grammar','A2',1,874,'homework',NULL);
INSERT INTO "events" VALUES(209,2,'2026-10-25T11:52:00+00:00','2026-10-25','answer',203,'Prepositions of place & movement','grammar','A2',0,1040,'homework',NULL);
INSERT INTO "events" VALUES(210,2,'2026-10-25T11:52:03+00:00','2026-10-25','answer',135,'Comparatives & Superlatives','grammar','A2',1,2074,'homework',NULL);
INSERT INTO "events" VALUES(211,2,'2026-10-25T11:52:05+00:00','2026-10-25','answer',377,'Feelings & describing people','vocabulary','A2',1,1004,'homework',NULL);
INSERT INTO "events" VALUES(212,2,'2026-10-25T11:52:08+00:00','2026-10-25','answer',264,'Conditionals (zero & first)','grammar','A2',0,1105,'homework',NULL);
INSERT INTO "events" VALUES(213,2,'2026-10-25T11:52:08+00:00','2026-10-25','hw_complete',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 5, "correct": 4, "total": 15}');
INSERT INTO "events" VALUES(214,2,'2026-10-25T11:52:08+00:00','2026-10-25','reward',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "xp", "amount": 10, "reason": "Бонус за домашку в срок"}');
INSERT INTO "events" VALUES(215,5,'2026-10-25T12:36:08+00:00','2026-10-25','register',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(216,5,'2026-10-25T12:36:26+00:00','2026-10-25','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'daily',NULL);
INSERT INTO "events" VALUES(217,4,'2026-10-25T13:06:31+00:00','2026-10-25','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(218,4,'2026-10-25T13:06:32+00:00','2026-10-25','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(219,6,'2026-10-25T13:09:44+00:00','2026-10-25','register',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(220,6,'2026-10-25T13:10:02+00:00','2026-10-25','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'daily',NULL);
INSERT INTO "events" VALUES(221,3,'2026-10-25T13:42:15+00:00','2026-10-25','hw_start',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 8}');
INSERT INTO "events" VALUES(222,3,'2026-10-25T13:42:21+00:00','2026-10-25','answer',351,'Town & directions','vocabulary','A1',0,6357,'homework',NULL);
INSERT INTO "events" VALUES(223,3,'2026-10-25T13:42:28+00:00','2026-10-25','answer',352,'Town & directions','vocabulary','A1',1,5732,'homework',NULL);
INSERT INTO "events" VALUES(224,3,'2026-10-25T13:42:36+00:00','2026-10-25','answer',350,'Town & directions','vocabulary','A1',1,4175,'homework',NULL);
INSERT INTO "events" VALUES(225,3,'2026-10-25T13:42:38+00:00','2026-10-25','answer',353,'Town & directions','vocabulary','A2',0,904,'homework',NULL);
INSERT INTO "events" VALUES(226,3,'2026-10-25T13:42:40+00:00','2026-10-25','answer',354,'Town & directions','vocabulary','A2',0,860,'homework',NULL);
INSERT INTO "events" VALUES(227,3,'2026-10-25T13:42:40+00:00','2026-10-25','hw_complete',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 8, "correct": 2, "total": 5}');
INSERT INTO "events" VALUES(228,3,'2026-10-25T13:42:40+00:00','2026-10-25','reward',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "xp", "amount": 10, "reason": "Бонус за домашку в срок"}');
INSERT INTO "events" VALUES(229,2,'2026-10-25T13:45:20+00:00','2026-10-25','hw_start',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 8}');
INSERT INTO "events" VALUES(230,2,'2026-10-25T13:45:23+00:00','2026-10-25','answer',351,'Town & directions','vocabulary','A1',1,3046,'homework',NULL);
INSERT INTO "events" VALUES(231,2,'2026-10-25T13:45:28+00:00','2026-10-25','answer',352,'Town & directions','vocabulary','A1',1,4120,'homework',NULL);
INSERT INTO "events" VALUES(232,2,'2026-10-25T13:45:34+00:00','2026-10-25','answer',350,'Town & directions','vocabulary','A1',1,4055,'homework',NULL);
INSERT INTO "events" VALUES(233,2,'2026-10-25T13:45:40+00:00','2026-10-25','answer',353,'Town & directions','vocabulary','A2',1,4511,'homework',NULL);
INSERT INTO "events" VALUES(234,2,'2026-10-25T13:45:49+00:00','2026-10-25','answer',354,'Town & directions','vocabulary','A2',1,8723,'homework',NULL);
INSERT INTO "events" VALUES(235,2,'2026-10-25T13:45:49+00:00','2026-10-25','hw_complete',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 8, "correct": 5, "total": 5}');
INSERT INTO "events" VALUES(236,2,'2026-10-25T13:45:49+00:00','2026-10-25','reward',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "xp", "amount": 10, "reason": "Бонус за домашку в срок"}');
INSERT INTO "events" VALUES(237,3,'2026-10-25T14:50:07+00:00','2026-10-25','penalty',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "coins", "amount": -9999, "reason": "Слишком расстроена"}');
INSERT INTO "events" VALUES(238,3,'2026-10-25T14:54:47+00:00','2026-10-25','reward',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "coins", "amount": 9999, "reason": "За самую сочную жопку в мире🔥"}');
INSERT INTO "events" VALUES(239,5,'2026-10-25T17:32:11+00:00','2026-10-25','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(240,5,'2026-10-25T20:00:38+00:00','2026-10-25','profile_view',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
INSERT INTO "events" VALUES(241,5,'2026-10-25T20:01:01+00:00','2026-10-25','quiz_start',NULL,NULL,NULL,NULL,NULL,NULL,'practice',NULL);
INSERT INTO "events" VALUES(242,5,'2026-10-25T20:01:23+00:00','2026-10-25','answer',216,'Adverbs (frequency, manner)','grammar','A1',0,21392,'practice',NULL);
INSERT INTO "events" VALUES(243,5,'2026-10-25T20:01:43+00:00','2026-10-25','answer',226,'Modal verbs & would like','grammar','A2',0,14337,'practice',NULL);
INSERT INTO "events" VALUES(244,5,'2026-10-25T20:02:00+00:00','2026-10-25','answer',225,'Modal verbs & would like','grammar','A2',0,13355,'practice',NULL);
INSERT INTO "events" VALUES(245,5,'2026-10-25T20:02:10+00:00','2026-10-25','answer',252,'Present Perfect','grammar','A2',0,8605,'practice',NULL);
INSERT INTO "events" VALUES(246,5,'2026-10-25T20:02:24+00:00','2026-10-25','answer',108,'Basic verbs (be, have got, can)','grammar','A1',0,10416,'practice',NULL);
INSERT INTO "events" VALUES(247,5,'2026-10-25T20:02:24+00:00','2026-10-25','quiz_complete',NULL,NULL,NULL,NULL,NULL,NULL,'practice','{"correct": 0, "total": 5}');
INSERT INTO "events" VALUES(248,5,'2026-10-25T20:04:13+00:00','2026-10-25','hw_start',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 10}');
INSERT INTO "events" VALUES(249,5,'2026-10-25T20:04:35+00:00','2026-10-25','answer',111,'Present Simple','grammar','A1',1,22539,'homework',NULL);
INSERT INTO "events" VALUES(250,5,'2026-10-25T20:04:53+00:00','2026-10-25','answer',112,'Present Simple','grammar','A1',0,12741,'homework',NULL);
INSERT INTO "events" VALUES(251,5,'2026-10-25T20:05:21+00:00','2026-10-25','answer',109,'Present Simple','grammar','A1',1,21081,'homework',NULL);
INSERT INTO "events" VALUES(252,5,'2026-10-25T20:05:37+00:00','2026-10-25','answer',110,'Present Simple','grammar','A1',0,11395,'homework',NULL);
INSERT INTO "events" VALUES(253,5,'2026-10-25T20:06:06+00:00','2026-10-25','answer',114,'Present Simple','grammar','A2',1,23490,'homework',NULL);
INSERT INTO "events" VALUES(254,5,'2026-10-25T20:06:41+00:00','2026-10-25','answer',116,'Present Simple','grammar','A2',1,33560,'homework',NULL);
INSERT INTO "events" VALUES(255,5,'2026-10-25T20:07:12+00:00','2026-10-25','answer',113,'Present Simple','grammar','A2',0,24882,'homework',NULL);
INSERT INTO "events" VALUES(256,5,'2026-10-25T20:07:27+00:00','2026-10-25','answer',115,'Present Simple','grammar','A2',0,11736,'homework',NULL);
INSERT INTO "events" VALUES(257,5,'2026-10-25T20:07:27+00:00','2026-10-25','hw_complete',NULL,NULL,NULL,NULL,NULL,NULL,'homework','{"hw_id": 10, "correct": 4, "total": 8}');
INSERT INTO "events" VALUES(258,5,'2026-10-25T20:07:27+00:00','2026-10-25','reward',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{"kind": "xp", "amount": 10, "reason": "Бонус за домашку в срок"}');
INSERT INTO "events" VALUES(259,5,'2026-10-25T20:07:42+00:00','2026-10-25','cheatsheet_view',NULL,'Present Simple',NULL,NULL,NULL,NULL,NULL,NULL);
CREATE TABLE groups (
    id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE NOT NULL, target_cefr TEXT, created_at TEXT);
INSERT INTO "groups" VALUES(1,'Мои_тестировщики',NULL,'2026-10-25T00:42:51+00:00');
INSERT INTO "groups" VALUES(2,'A1-Девочки',NULL,'2026-10-25T12:38:35+00:00');
INSERT INTO "groups" VALUES(3,'Тима_инд',NULL,'2026-10-25T13:43:53+00:00');
CREATE TABLE homework (
    id INTEGER PRIMARY KEY AUTOINCREMENT, kind TEXT NOT NULL, title TEXT NOT NULL, description TEXT,
    topic TEXT, group_id INTEGER REFERENCES groups(id), due_date TEXT, active INTEGER NOT NULL DEFAULT 1,
    created_by INTEGER REFERENCES users(id), created_at TEXT NOT NULL);
INSERT INTO "homework" VALUES(1,'quiz','ejkrgbsjdfg',NULL,'Past Simple',NULL,'2026-10-26',0,1,'2026-10-25T00:17:39+00:00');
INSERT INTO "homework" VALUES(2,'quiz','лтшм',NULL,NULL,1,NULL,0,1,'2026-10-25T00:44:44+00:00');
INSERT INTO "homework" VALUES(3,'quiz','Ммм',NULL,NULL,1,NULL,0,1,'2026-10-25T10:33:43+00:00');
INSERT INTO "homework" VALUES(4,'quiz','Надо потренироваться',NULL,NULL,1,NULL,0,1,'2026-10-25T10:36:32+00:00');
INSERT INTO "homework" VALUES(5,'quiz','Домашка сиу',NULL,NULL,1,'2026-10-26',0,1,'2026-10-25T11:50:41+00:00');
INSERT INTO "homework" VALUES(6,'quiz','PRESENT SIMPLE_Домашка',NULL,'Present Simple',2,'2026-10-28',0,1,'2026-10-25T12:40:47+00:00');
INSERT INTO "homework" VALUES(7,'quiz','Пять заданий',NULL,'Town & directions',1,'2026-10-26',0,1,'2026-10-25T13:34:41+00:00');
INSERT INTO "homework" VALUES(8,'quiz','пмчсм вораим',NULL,'Town & directions',1,'2026-10-26',0,1,'2026-10-25T13:40:21+00:00');
INSERT INTO "homework" VALUES(9,'quiz','Past Simple ДЗшка',NULL,'Past Simple',3,'2026-11-01',1,1,'2026-10-25T13:45:05+00:00');
INSERT INTO "homework" VALUES(10,'quiz','Present simple ДЗшка',NULL,'Present Simple',2,'2026-10-28',1,1,'2026-10-25T13:45:35+00:00');
CREATE TABLE homework_answers (
    homework_id INTEGER NOT NULL, user_id INTEGER NOT NULL, question_id INTEGER NOT NULL,
    is_correct INTEGER NOT NULL, ts TEXT NOT NULL, PRIMARY KEY (homework_id, user_id, question_id));
INSERT INTO "homework_answers" VALUES(2,2,127,1,'2026-10-25T10:00:23+00:00');
INSERT INTO "homework_answers" VALUES(2,2,109,1,'2026-10-25T10:00:28+00:00');
INSERT INTO "homework_answers" VALUES(2,2,101,1,'2026-10-25T10:00:31+00:00');
INSERT INTO "homework_answers" VALUES(2,2,121,1,'2026-10-25T10:00:41+00:00');
INSERT INTO "homework_answers" VALUES(2,2,128,1,'2026-10-25T10:00:50+00:00');
INSERT INTO "homework_answers" VALUES(2,2,136,1,'2026-10-25T10:00:56+00:00');
INSERT INTO "homework_answers" VALUES(2,2,114,1,'2026-10-25T10:01:02+00:00');
INSERT INTO "homework_answers" VALUES(2,2,116,1,'2026-10-25T10:01:15+00:00');
INSERT INTO "homework_answers" VALUES(2,2,124,0,'2026-10-25T10:01:23+00:00');
INSERT INTO "homework_answers" VALUES(2,2,140,1,'2026-10-25T10:01:34+00:00');
INSERT INTO "homework_answers" VALUES(2,3,127,1,'2026-10-25T10:13:48+00:00');
INSERT INTO "homework_answers" VALUES(2,3,109,1,'2026-10-25T10:13:57+00:00');
INSERT INTO "homework_answers" VALUES(2,3,101,1,'2026-10-25T10:14:05+00:00');
INSERT INTO "homework_answers" VALUES(2,3,121,0,'2026-10-25T10:14:13+00:00');
INSERT INTO "homework_answers" VALUES(2,3,128,1,'2026-10-25T10:14:36+00:00');
INSERT INTO "homework_answers" VALUES(2,3,136,1,'2026-10-25T10:15:23+00:00');
INSERT INTO "homework_answers" VALUES(2,3,114,1,'2026-10-25T10:15:46+00:00');
INSERT INTO "homework_answers" VALUES(2,3,116,1,'2026-10-25T10:16:06+00:00');
INSERT INTO "homework_answers" VALUES(2,3,124,0,'2026-10-25T10:16:44+00:00');
INSERT INTO "homework_answers" VALUES(2,3,140,1,'2026-10-25T10:17:43+00:00');
INSERT INTO "homework_answers" VALUES(3,3,120,1,'2026-10-25T10:34:56+00:00');
INSERT INTO "homework_answers" VALUES(3,3,103,1,'2026-10-25T10:35:13+00:00');
INSERT INTO "homework_answers" VALUES(3,3,105,1,'2026-10-25T10:35:23+00:00');
INSERT INTO "homework_answers" VALUES(3,3,101,1,'2026-10-25T10:35:31+00:00');
INSERT INTO "homework_answers" VALUES(3,3,108,1,'2026-10-25T10:35:53+00:00');
INSERT INTO "homework_answers" VALUES(3,3,126,1,'2026-10-25T10:36:06+00:00');
INSERT INTO "homework_answers" VALUES(3,3,125,1,'2026-10-25T10:36:14+00:00');
INSERT INTO "homework_answers" VALUES(4,2,340,1,'2026-10-25T10:37:26+00:00');
INSERT INTO "homework_answers" VALUES(4,2,125,1,'2026-10-25T10:37:33+00:00');
INSERT INTO "homework_answers" VALUES(4,2,332,1,'2026-10-25T10:37:41+00:00');
INSERT INTO "homework_answers" VALUES(4,2,189,1,'2026-10-25T10:37:45+00:00');
INSERT INTO "homework_answers" VALUES(4,2,149,1,'2026-10-25T10:37:50+00:00');
INSERT INTO "homework_answers" VALUES(4,2,326,1,'2026-10-25T10:37:54+00:00');
INSERT INTO "homework_answers" VALUES(3,3,119,1,'2026-10-25T10:38:00+00:00');
INSERT INTO "homework_answers" VALUES(4,2,200,1,'2026-10-25T10:38:09+00:00');
INSERT INTO "homework_answers" VALUES(4,2,357,1,'2026-10-25T10:38:15+00:00');
INSERT INTO "homework_answers" VALUES(3,3,104,1,'2026-10-25T10:38:18+00:00');
INSERT INTO "homework_answers" VALUES(4,2,280,1,'2026-10-25T10:38:23+00:00');
INSERT INTO "homework_answers" VALUES(4,2,188,1,'2026-10-25T10:38:31+00:00');
INSERT INTO "homework_answers" VALUES(3,3,117,1,'2026-10-25T10:38:37+00:00');
INSERT INTO "homework_answers" VALUES(4,2,237,1,'2026-10-25T10:38:40+00:00');
INSERT INTO "homework_answers" VALUES(4,2,122,1,'2026-10-25T10:38:45+00:00');
INSERT INTO "homework_answers" VALUES(3,3,109,1,'2026-10-25T10:38:46+00:00');
INSERT INTO "homework_answers" VALUES(4,2,220,1,'2026-10-25T10:38:57+00:00');
INSERT INTO "homework_answers" VALUES(3,3,106,1,'2026-10-25T10:39:01+00:00');
INSERT INTO "homework_answers" VALUES(4,2,371,1,'2026-10-25T10:39:04+00:00');
INSERT INTO "homework_answers" VALUES(3,3,110,1,'2026-10-25T10:39:09+00:00');
INSERT INTO "homework_answers" VALUES(4,2,324,1,'2026-10-25T10:39:11+00:00');
INSERT INTO "homework_answers" VALUES(3,3,107,1,'2026-10-25T10:39:20+00:00');
INSERT INTO "homework_answers" VALUES(4,2,268,0,'2026-10-25T10:39:23+00:00');
INSERT INTO "homework_answers" VALUES(3,3,128,1,'2026-10-25T10:39:36+00:00');
INSERT INTO "homework_answers" VALUES(3,3,138,1,'2026-10-25T10:39:46+00:00');
INSERT INTO "homework_answers" VALUES(4,2,265,1,'2026-10-25T10:39:55+00:00');
INSERT INTO "homework_answers" VALUES(3,3,137,1,'2026-10-25T10:39:56+00:00');
INSERT INTO "homework_answers" VALUES(3,3,131,1,'2026-10-25T10:40:16+00:00');
INSERT INTO "homework_answers" VALUES(4,2,398,0,'2026-10-25T10:40:17+00:00');
INSERT INTO "homework_answers" VALUES(4,2,393,1,'2026-10-25T10:40:43+00:00');
INSERT INTO "homework_answers" VALUES(3,3,139,1,'2026-10-25T10:40:49+00:00');
INSERT INTO "homework_answers" VALUES(3,3,136,1,'2026-10-25T10:41:03+00:00');
INSERT INTO "homework_answers" VALUES(4,3,340,1,'2026-10-25T10:41:42+00:00');
INSERT INTO "homework_answers" VALUES(4,3,125,1,'2026-10-25T10:41:52+00:00');
INSERT INTO "homework_answers" VALUES(4,3,332,1,'2026-10-25T10:42:06+00:00');
INSERT INTO "homework_answers" VALUES(4,3,189,1,'2026-10-25T10:42:16+00:00');
INSERT INTO "homework_answers" VALUES(4,3,149,1,'2026-10-25T10:42:30+00:00');
INSERT INTO "homework_answers" VALUES(4,3,326,1,'2026-10-25T10:42:37+00:00');
INSERT INTO "homework_answers" VALUES(4,3,200,1,'2026-10-25T10:42:46+00:00');
INSERT INTO "homework_answers" VALUES(4,3,357,1,'2026-10-25T10:43:01+00:00');
INSERT INTO "homework_answers" VALUES(4,2,107,1,'2026-10-25T10:43:04+00:00');
INSERT INTO "homework_answers" VALUES(4,3,280,1,'2026-10-25T10:43:09+00:00');
INSERT INTO "homework_answers" VALUES(4,3,188,1,'2026-10-25T10:43:20+00:00');
INSERT INTO "homework_answers" VALUES(4,3,237,1,'2026-10-25T10:43:59+00:00');
INSERT INTO "homework_answers" VALUES(4,3,122,1,'2026-10-25T10:44:22+00:00');
INSERT INTO "homework_answers" VALUES(4,3,220,0,'2026-10-25T10:44:51+00:00');
INSERT INTO "homework_answers" VALUES(4,3,371,1,'2026-10-25T10:45:15+00:00');
INSERT INTO "homework_answers" VALUES(4,3,324,1,'2026-10-25T10:45:47+00:00');
INSERT INTO "homework_answers" VALUES(4,3,268,1,'2026-10-25T10:46:23+00:00');
INSERT INTO "homework_answers" VALUES(4,3,265,1,'2026-10-25T10:46:51+00:00');
INSERT INTO "homework_answers" VALUES(4,3,398,1,'2026-10-25T10:47:38+00:00');
INSERT INTO "homework_answers" VALUES(4,3,393,1,'2026-10-25T10:48:06+00:00');
INSERT INTO "homework_answers" VALUES(4,3,107,1,'2026-10-25T10:48:21+00:00');
INSERT INTO "homework_answers" VALUES(5,2,387,0,'2026-10-25T11:51:32+00:00');
INSERT INTO "homework_answers" VALUES(5,2,298,0,'2026-10-25T11:51:36+00:00');
INSERT INTO "homework_answers" VALUES(5,2,253,0,'2026-10-25T11:51:38+00:00');
INSERT INTO "homework_answers" VALUES(5,2,182,0,'2026-10-25T11:51:41+00:00');
INSERT INTO "homework_answers" VALUES(5,2,207,0,'2026-10-25T11:51:44+00:00');
INSERT INTO "homework_answers" VALUES(5,2,238,0,'2026-10-25T11:51:46+00:00');
INSERT INTO "homework_answers" VALUES(5,2,265,1,'2026-10-25T11:51:48+00:00');
INSERT INTO "homework_answers" VALUES(5,2,260,0,'2026-10-25T11:51:52+00:00');
INSERT INTO "homework_answers" VALUES(5,2,254,0,'2026-10-25T11:51:54+00:00');
INSERT INTO "homework_answers" VALUES(5,2,179,0,'2026-10-25T11:51:57+00:00');
INSERT INTO "homework_answers" VALUES(5,2,195,1,'2026-10-25T11:51:58+00:00');
INSERT INTO "homework_answers" VALUES(5,2,203,0,'2026-10-25T11:52:00+00:00');
INSERT INTO "homework_answers" VALUES(5,2,135,1,'2026-10-25T11:52:03+00:00');
INSERT INTO "homework_answers" VALUES(5,2,377,1,'2026-10-25T11:52:05+00:00');
INSERT INTO "homework_answers" VALUES(5,2,264,0,'2026-10-25T11:52:08+00:00');
INSERT INTO "homework_answers" VALUES(8,3,351,0,'2026-10-25T13:42:21+00:00');
INSERT INTO "homework_answers" VALUES(8,3,352,1,'2026-10-25T13:42:28+00:00');
INSERT INTO "homework_answers" VALUES(8,3,350,1,'2026-10-25T13:42:36+00:00');
INSERT INTO "homework_answers" VALUES(8,3,353,0,'2026-10-25T13:42:38+00:00');
INSERT INTO "homework_answers" VALUES(8,3,354,0,'2026-10-25T13:42:40+00:00');
INSERT INTO "homework_answers" VALUES(8,2,351,1,'2026-10-25T13:45:23+00:00');
INSERT INTO "homework_answers" VALUES(8,2,352,1,'2026-10-25T13:45:28+00:00');
INSERT INTO "homework_answers" VALUES(8,2,350,1,'2026-10-25T13:45:34+00:00');
INSERT INTO "homework_answers" VALUES(8,2,353,1,'2026-10-25T13:45:40+00:00');
INSERT INTO "homework_answers" VALUES(8,2,354,1,'2026-10-25T13:45:49+00:00');
INSERT INTO "homework_answers" VALUES(10,5,111,1,'2026-10-25T20:04:35+00:00');
INSERT INTO "homework_answers" VALUES(10,5,112,0,'2026-10-25T20:04:53+00:00');
INSERT INTO "homework_answers" VALUES(10,5,109,1,'2026-10-25T20:05:21+00:00');
INSERT INTO "homework_answers" VALUES(10,5,110,0,'2026-10-25T20:05:37+00:00');
INSERT INTO "homework_answers" VALUES(10,5,114,1,'2026-10-25T20:06:06+00:00');
INSERT INTO "homework_answers" VALUES(10,5,116,1,'2026-10-25T20:06:41+00:00');
INSERT INTO "homework_answers" VALUES(10,5,113,0,'2026-10-25T20:07:12+00:00');
INSERT INTO "homework_answers" VALUES(10,5,115,0,'2026-10-25T20:07:27+00:00');
CREATE TABLE homework_questions (
    homework_id INTEGER NOT NULL REFERENCES homework(id), question_id INTEGER NOT NULL REFERENCES questions(id),
    pos INTEGER NOT NULL, PRIMARY KEY (homework_id, question_id));
INSERT INTO "homework_questions" VALUES(1,126,0);
INSERT INTO "homework_questions" VALUES(1,127,1);
INSERT INTO "homework_questions" VALUES(1,125,2);
INSERT INTO "homework_questions" VALUES(1,130,3);
INSERT INTO "homework_questions" VALUES(1,131,4);
INSERT INTO "homework_questions" VALUES(1,128,5);
INSERT INTO "homework_questions" VALUES(1,129,6);
INSERT INTO "homework_questions" VALUES(1,132,7);
INSERT INTO "homework_questions" VALUES(2,127,0);
INSERT INTO "homework_questions" VALUES(2,109,1);
INSERT INTO "homework_questions" VALUES(2,101,2);
INSERT INTO "homework_questions" VALUES(2,121,3);
INSERT INTO "homework_questions" VALUES(2,128,4);
INSERT INTO "homework_questions" VALUES(2,136,5);
INSERT INTO "homework_questions" VALUES(2,114,6);
INSERT INTO "homework_questions" VALUES(2,116,7);
INSERT INTO "homework_questions" VALUES(2,124,8);
INSERT INTO "homework_questions" VALUES(2,140,9);
INSERT INTO "homework_questions" VALUES(3,120,0);
INSERT INTO "homework_questions" VALUES(3,103,1);
INSERT INTO "homework_questions" VALUES(3,105,2);
INSERT INTO "homework_questions" VALUES(3,101,3);
INSERT INTO "homework_questions" VALUES(3,108,4);
INSERT INTO "homework_questions" VALUES(3,126,5);
INSERT INTO "homework_questions" VALUES(3,125,6);
INSERT INTO "homework_questions" VALUES(3,119,7);
INSERT INTO "homework_questions" VALUES(3,104,8);
INSERT INTO "homework_questions" VALUES(3,117,9);
INSERT INTO "homework_questions" VALUES(3,109,10);
INSERT INTO "homework_questions" VALUES(3,106,11);
INSERT INTO "homework_questions" VALUES(3,110,12);
INSERT INTO "homework_questions" VALUES(3,107,13);
INSERT INTO "homework_questions" VALUES(3,128,14);
INSERT INTO "homework_questions" VALUES(3,138,15);
INSERT INTO "homework_questions" VALUES(3,137,16);
INSERT INTO "homework_questions" VALUES(3,131,17);
INSERT INTO "homework_questions" VALUES(3,139,18);
INSERT INTO "homework_questions" VALUES(3,136,19);
INSERT INTO "homework_questions" VALUES(4,340,0);
INSERT INTO "homework_questions" VALUES(4,125,1);
INSERT INTO "homework_questions" VALUES(4,332,2);
INSERT INTO "homework_questions" VALUES(4,189,3);
INSERT INTO "homework_questions" VALUES(4,149,4);
INSERT INTO "homework_questions" VALUES(4,326,5);
INSERT INTO "homework_questions" VALUES(4,200,6);
INSERT INTO "homework_questions" VALUES(4,357,7);
INSERT INTO "homework_questions" VALUES(4,280,8);
INSERT INTO "homework_questions" VALUES(4,188,9);
INSERT INTO "homework_questions" VALUES(4,237,10);
INSERT INTO "homework_questions" VALUES(4,122,11);
INSERT INTO "homework_questions" VALUES(4,220,12);
INSERT INTO "homework_questions" VALUES(4,371,13);
INSERT INTO "homework_questions" VALUES(4,324,14);
INSERT INTO "homework_questions" VALUES(4,268,15);
INSERT INTO "homework_questions" VALUES(4,265,16);
INSERT INTO "homework_questions" VALUES(4,398,17);
INSERT INTO "homework_questions" VALUES(4,393,18);
INSERT INTO "homework_questions" VALUES(4,107,19);
INSERT INTO "homework_questions" VALUES(5,387,0);
INSERT INTO "homework_questions" VALUES(5,298,1);
INSERT INTO "homework_questions" VALUES(5,253,2);
INSERT INTO "homework_questions" VALUES(5,182,3);
INSERT INTO "homework_questions" VALUES(5,207,4);
INSERT INTO "homework_questions" VALUES(5,238,5);
INSERT INTO "homework_questions" VALUES(5,265,6);
INSERT INTO "homework_questions" VALUES(5,260,7);
INSERT INTO "homework_questions" VALUES(5,254,8);
INSERT INTO "homework_questions" VALUES(5,179,9);
INSERT INTO "homework_questions" VALUES(5,195,10);
INSERT INTO "homework_questions" VALUES(5,203,11);
INSERT INTO "homework_questions" VALUES(5,135,12);
INSERT INTO "homework_questions" VALUES(5,377,13);
INSERT INTO "homework_questions" VALUES(5,264,14);
INSERT INTO "homework_questions" VALUES(6,112,0);
INSERT INTO "homework_questions" VALUES(6,111,1);
INSERT INTO "homework_questions" VALUES(6,110,2);
INSERT INTO "homework_questions" VALUES(6,109,3);
INSERT INTO "homework_questions" VALUES(6,114,4);
INSERT INTO "homework_questions" VALUES(6,116,5);
INSERT INTO "homework_questions" VALUES(6,115,6);
INSERT INTO "homework_questions" VALUES(6,113,7);
INSERT INTO "homework_questions" VALUES(7,349,0);
INSERT INTO "homework_questions" VALUES(7,384,1);
INSERT INTO "homework_questions" VALUES(7,353,2);
INSERT INTO "homework_questions" VALUES(7,399,3);
INSERT INTO "homework_questions" VALUES(7,354,4);
INSERT INTO "homework_questions" VALUES(8,351,0);
INSERT INTO "homework_questions" VALUES(8,352,1);
INSERT INTO "homework_questions" VALUES(8,350,2);
INSERT INTO "homework_questions" VALUES(8,353,3);
INSERT INTO "homework_questions" VALUES(8,354,4);
INSERT INTO "homework_questions" VALUES(9,125,0);
INSERT INTO "homework_questions" VALUES(9,126,1);
INSERT INTO "homework_questions" VALUES(9,127,2);
INSERT INTO "homework_questions" VALUES(9,131,3);
INSERT INTO "homework_questions" VALUES(9,129,4);
INSERT INTO "homework_questions" VALUES(9,132,5);
INSERT INTO "homework_questions" VALUES(9,130,6);
INSERT INTO "homework_questions" VALUES(9,128,7);
INSERT INTO "homework_questions" VALUES(10,111,0);
INSERT INTO "homework_questions" VALUES(10,112,1);
INSERT INTO "homework_questions" VALUES(10,109,2);
INSERT INTO "homework_questions" VALUES(10,110,3);
INSERT INTO "homework_questions" VALUES(10,114,4);
INSERT INTO "homework_questions" VALUES(10,116,5);
INSERT INTO "homework_questions" VALUES(10,113,6);
INSERT INTO "homework_questions" VALUES(10,115,7);
CREATE TABLE homework_status (
    homework_id INTEGER NOT NULL, user_id INTEGER NOT NULL, status TEXT NOT NULL, score INTEGER, total INTEGER,
    late INTEGER NOT NULL DEFAULT 0, submitted_at TEXT, completed_at TEXT, teacher_comment TEXT, sub_chat INTEGER, sub_msg INTEGER,
    PRIMARY KEY (homework_id, user_id));
INSERT INTO "homework_status" VALUES(2,2,'done',9,10,0,NULL,'2026-10-25T10:01:34+00:00',NULL,NULL,NULL);
INSERT INTO "homework_status" VALUES(2,3,'done',8,10,0,NULL,'2026-10-25T10:17:43+00:00',NULL,NULL,NULL);
INSERT INTO "homework_status" VALUES(3,3,'done',20,20,0,NULL,'2026-10-25T10:41:03+00:00',NULL,NULL,NULL);
INSERT INTO "homework_status" VALUES(4,2,'done',18,20,0,NULL,'2026-10-25T10:43:05+00:00',NULL,NULL,NULL);
INSERT INTO "homework_status" VALUES(4,3,'done',19,20,0,NULL,'2026-10-25T10:48:21+00:00',NULL,NULL,NULL);
INSERT INTO "homework_status" VALUES(5,2,'done',4,15,0,NULL,'2026-10-25T11:52:08+00:00',NULL,NULL,NULL);
INSERT INTO "homework_status" VALUES(8,3,'done',2,5,0,NULL,'2026-10-25T13:42:40+00:00',NULL,NULL,NULL);
INSERT INTO "homework_status" VALUES(8,2,'done',5,5,0,NULL,'2026-10-25T13:45:49+00:00',NULL,NULL,NULL);
INSERT INTO "homework_status" VALUES(10,5,'done',4,8,0,NULL,'2026-10-25T20:07:27+00:00',NULL,NULL,NULL);
CREATE TABLE questions (
    id INTEGER PRIMARY KEY, topic TEXT NOT NULL, skill TEXT NOT NULL, cefr TEXT NOT NULL,
    type TEXT NOT NULL, question TEXT NOT NULL,
    option_a TEXT, option_b TEXT, option_c TEXT, option_d TEXT,
    correct TEXT NOT NULL, explanation TEXT, active INTEGER NOT NULL DEFAULT 1);
INSERT INTO "questions" VALUES(101,'Basic verbs (be, have got, can)','grammar','A1','choice','I ___ a teacher.','am','be','are','is','a','С местоимением I используется am.',1);
INSERT INTO "questions" VALUES(102,'Basic verbs (be, have got, can)','grammar','A1','choice','They ___ from Spain.','are','be','am','is','a','С they используется are.',1);
INSERT INTO "questions" VALUES(103,'Basic verbs (be, have got, can)','grammar','A1','choice','She ___ got two brothers.','have','has','having','haves','b','С he/she/it используется has got.',1);
INSERT INTO "questions" VALUES(104,'Basic verbs (be, have got, can)','grammar','A1','choice','My little brother is only two. He ___ read yet.','can','cans','doesn''t can','can''t','d','Отрицание от can: can''t (cannot). Окончание -s не нужно.',1);
INSERT INTO "questions" VALUES(105,'Basic verbs (be, have got, can)','grammar','A1','choice','___ your sister at home now?','Are','Is','Does','Do','b','Вопрос с to be: глагол ставится перед подлежащим. Для she/your sister это is.',1);
INSERT INTO "questions" VALUES(106,'Basic verbs (be, have got, can)','grammar','A1','choice','We ___ got a car. We walk everywhere.','don''t','hasn''t','haven''t','aren''t','c','С we используется have got, отрицание: haven''t got.',1);
INSERT INTO "questions" VALUES(107,'Basic verbs (be, have got, can)','grammar','A2','choice','When I was five, I ___ ride a bike.','couldn''t','wasn''t can','didn''t can','can''t','a','Прошедшее время от can: could, отрицание: couldn''t. По смыслу в пять лет ещё не умел.',1);
INSERT INTO "questions" VALUES(108,'Basic verbs (be, have got, can)','grammar','A1','text','There ___ three books on the table. (be)','','','','','are','После there с множественным числом: there are.',1);
INSERT INTO "questions" VALUES(109,'Present Simple','grammar','A1','choice','He ___ coffee every morning.','is drink','drink','drinks','drinking','c','Present Simple, he/she/it: к глаголу добавляется -s.',1);
INSERT INTO "questions" VALUES(110,'Present Simple','grammar','A1','choice','I ___ like fish.','doesn''t','don''t','not','am not','b','Отрицание в Present Simple: don''t + глагол (для I/you/we/they).',1);
INSERT INTO "questions" VALUES(111,'Present Simple','grammar','A1','choice','___ she work in a bank?','Does','Is','Are','Do','a','Вопрос в Present Simple с she: Does + подлежащее + глагол.',1);
INSERT INTO "questions" VALUES(112,'Present Simple','grammar','A1','choice','My mother ___ TV in the evening.','watches','watchs','watching','watch','a','После -ch, -sh, -s, -x добавляется -es: watch → watches.',1);
INSERT INTO "questions" VALUES(113,'Present Simple','grammar','A2','choice','How often ___ you go to the gym?','is','does','are','do','d','Вопрос в Present Simple с you: do.',1);
INSERT INTO "questions" VALUES(114,'Present Simple','grammar','A2','text','She usually ___ up at six. (get)','','','','','gets','Present Simple, she: get → gets.',1);
INSERT INTO "questions" VALUES(115,'Present Simple','grammar','A2','choice','Water ___ at 100 degrees.','boil','boiled','boils','is boiling','c','Общеизвестные факты выражаются Present Simple.',1);
INSERT INTO "questions" VALUES(116,'Present Simple','grammar','A2','choice','Tom ___ always late for school.','does','do','is','has','c','Наречие always стоит после to be, но перед смысловым глаголом: Tom is always late.',1);
INSERT INTO "questions" VALUES(117,'Present Continuous','grammar','A1','choice','Look! It ___ now.','raining','rain','is raining','rains','c','Действие происходит прямо сейчас: is/am/are + глагол с -ing.',1);
INSERT INTO "questions" VALUES(118,'Present Continuous','grammar','A1','choice','I ___ to music at the moment.','listens','am listening','is listening','listen','b','At the moment указывает на Present Continuous: am + listening.',1);
INSERT INTO "questions" VALUES(119,'Present Continuous','grammar','A1','choice','They ___ football now. They''re at home.','aren''t play','don''t playing','aren''t playing','not play','c','Отрицание в Present Continuous: aren''t + глагол с -ing.',1);
INSERT INTO "questions" VALUES(120,'Present Continuous','grammar','A1','text','Write the -ing form: run → ___','','','','','running','Если глагол заканчивается на ударный слог из согласная-гласная-согласная, согласная удваивается.',1);
INSERT INTO "questions" VALUES(121,'Present Continuous','grammar','A2','choice','___ you watching TV right now?','Is','Do','Does','Are','d','Вопрос в Present Continuous с you: Are you + глагол с -ing.',1);
INSERT INTO "questions" VALUES(122,'Present Continuous','grammar','A2','choice','She ___ a shower. Call her later.','is having','having','have','has','a','Have в значении «принимать душ, есть, пить» допускает Continuous. Have как «иметь» нет.',1);
INSERT INTO "questions" VALUES(123,'Present Continuous','grammar','A2','choice','I usually ___ coffee, but today I ___ tea.','drink / drink','am drinking / am drinking','am drinking / drink','drink / am drinking','d','Usually указывает на привычку (Present Simple), today на временное действие (Present Continuous).',1);
INSERT INTO "questions" VALUES(124,'Present Continuous','grammar','B1','choice','I ___ my cousin this weekend. We''ve bought tickets.','visit','am visiting','have visited','visited','b','Запланированные договорённости на ближайшее будущее часто выражаются Present Continuous.',1);
INSERT INTO "questions" VALUES(125,'Past Simple','grammar','A1','choice','Yesterday I ___ to the park.','gone','goed','went','go','c','Go — неправильный глагол, прошедшее время: went.',1);
INSERT INTO "questions" VALUES(126,'Past Simple','grammar','A1','choice','We ___ a film last night.','watchs','watch','watching','watched','d','Правильные глаголы в прошедшем времени получают окончание -ed.',1);
INSERT INTO "questions" VALUES(127,'Past Simple','grammar','A1','choice','He ___ at home yesterday.','were','be','is','was','d','Прошедшее время от to be: was (I/he/she/it), were (you/we/they).',1);
INSERT INTO "questions" VALUES(128,'Past Simple','grammar','A2','choice','She ___ to the party last Saturday.','didn''t go','not went','doesn''t go','didn''t went','a','Отрицание в Past Simple: didn''t + глагол в начальной форме.',1);
INSERT INTO "questions" VALUES(129,'Past Simple','grammar','A2','choice','___ you see Tom yesterday?','Have','Do','Did','Were','c','Вопрос в Past Simple строится с Did + подлежащее + глагол в начальной форме.',1);
INSERT INTO "questions" VALUES(130,'Past Simple','grammar','A2','text','Write the past form: buy → ___','','','','','bought','Buy — неправильный глагол: buy – bought – bought.',1);
INSERT INTO "questions" VALUES(131,'Past Simple','grammar','A2','text','Write the past form: study → ___','','','','','studied','Если глагол заканчивается на согласная + y, то y меняется на i и добавляется -ed.',1);
INSERT INTO "questions" VALUES(132,'Past Simple','grammar','A2','choice','Which sentence is correct?','Was she go home?','Did she went home?','Did she go home?','Does she went home?','c','После did глагол стоит в начальной форме: Did she go?',1);
INSERT INTO "questions" VALUES(133,'Comparatives & Superlatives','grammar','A2','choice','My house is ___ than yours.','bigger','biggest','more big','more bigger','a','Короткие прилагательные: -er. Если слог закрытый (big), согласная удваивается.',1);
INSERT INTO "questions" VALUES(134,'Comparatives & Superlatives','grammar','A2','choice','Mount Everest is the ___ mountain in the world.','higher','highest','most high','more high','b','Превосходная степень коротких прилагательных: the + -est.',1);
INSERT INTO "questions" VALUES(135,'Comparatives & Superlatives','grammar','A2','choice','This book is ___ than that one.','more interesting','interestinger','more interestinger','most interesting','a','Длинные прилагательные образуют сравнительную степень с more.',1);
INSERT INTO "questions" VALUES(136,'Comparatives & Superlatives','grammar','A2','text','Write the comparative: good → ___','','','','','better','Good — исключение: good – better – best.',1);
INSERT INTO "questions" VALUES(137,'Comparatives & Superlatives','grammar','A2','choice','Today is ___ than yesterday.','hoter','more hot','hottest','hotter','d','Hot → hotter: согласная удваивается.',1);
INSERT INTO "questions" VALUES(138,'Comparatives & Superlatives','grammar','A2','choice','He drives ___ than his brother.','more carefully','carefuller','most carefully','more careful','a','Наречия на -ly образуют сравнительную степень с more.',1);
INSERT INTO "questions" VALUES(139,'Comparatives & Superlatives','grammar','A2','choice','She is not ___ her sister.','taller as','tall as','so taller as','as tall as','d','Конструкция сравнения равенства: as + прилагательное + as.',1);
INSERT INTO "questions" VALUES(140,'Comparatives & Superlatives','grammar','B1','choice','The ___ you study, the better your results will be.','much','most','many','more','d','Конструкция the + сравнительная степень, the + сравнительная степень.',1);
INSERT INTO "questions" VALUES(141,'Articles & demonstratives (a/an/the, this/that)','grammar','A1','text','I have ___ orange in my bag. (a / an)','','','','','an','Перед гласным звуком используется an: an orange.',1);
INSERT INTO "questions" VALUES(142,'Articles & demonstratives (a/an/the, this/that)','grammar','A1','choice','I have a dog. ___ dog is very big.','The','A','An','(no article)','a','Собака уже упоминалась, поэтому используется определённый артикль the.',1);
INSERT INTO "questions" VALUES(143,'Articles & demonstratives (a/an/the, this/that)','grammar','A1','choice','Look at ___ sun! It''s so bright today.','a','the','an','(no article)','b','Солнце одно, поэтому используется the.',1);
INSERT INTO "questions" VALUES(144,'Articles & demonstratives (a/an/the, this/that)','grammar','A1','choice','I play ___ football on Sundays.','the','a','(no article)','an','c','Перед названиями видов спорта артикль не нужен: play football.',1);
INSERT INTO "questions" VALUES(145,'Articles & demonstratives (a/an/the, this/that)','grammar','A1','choice','(You hold a book in your hand.) ___ book is interesting.','That','These','Those','This','d','This/these — для предметов рядом, that/those — для далёких. Book в единственном числе, поэтому this.',1);
INSERT INTO "questions" VALUES(146,'Articles & demonstratives (a/an/the, this/that)','grammar','A1','choice','(The shoes are far from you, on a shelf.) ___ shoes are expensive.','These','Those','This','That','b','Shoes во множественном числе и находятся далеко: those.',1);
INSERT INTO "questions" VALUES(147,'Articles & demonstratives (a/an/the, this/that)','grammar','A2','choice','Which phrase is correct?','a hour','an university','an hour','a umbrella','c','Важен звук, а не буква: hour начинается с гласного звука (an hour), university — со звука /j/ (a university).',1);
INSERT INTO "questions" VALUES(148,'Articles & demonstratives (a/an/the, this/that)','grammar','A2','choice','I usually go to ___ bed at eleven.','the','a','an','(no article)','d','Устойчивое выражение go to bed употребляется без артикля.',1);
INSERT INTO "questions" VALUES(149,'Plurals & countable/uncountable nouns','grammar','A1','choice','I have two ___.','boxes','boxs','boxies','box''s','a','После -s, -x, -ch, -sh добавляется -es: box → boxes.',1);
INSERT INTO "questions" VALUES(150,'Plurals & countable/uncountable nouns','grammar','A1','choice','Look at those ___ in the park!','children','childs','childrens','childes','a','Child — исключение: множественное число children.',1);
INSERT INTO "questions" VALUES(151,'Plurals & countable/uncountable nouns','grammar','A1','text','Write the plural: woman → ___','','','','','women','Woman — исключение: множественное число women.',1);
INSERT INTO "questions" VALUES(152,'Plurals & countable/uncountable nouns','grammar','A1','text','Write the plural: baby → ___','','','','','babies','Если слово заканчивается на согласная + y, то y меняется на i и добавляется -es: baby → babies.',1);
INSERT INTO "questions" VALUES(153,'Plurals & countable/uncountable nouns','grammar','A1','choice','I drink ___ every morning.','a milk','milk','milks','many milks','b','Milk — неисчисляемое существительное: нет артикля a и нет множественного числа.',1);
INSERT INTO "questions" VALUES(154,'Plurals & countable/uncountable nouns','grammar','A2','choice','There are two ___ in the kitchen drawer.','knifes','knifs','knive','knives','d','В слове knife буква f меняется на v: knife → knives.',1);
INSERT INTO "questions" VALUES(155,'Plurals & countable/uncountable nouns','grammar','A2','choice','Can you give me some ___ about the museum?','informations','an information','information','a informations','c','Information — неисчисляемое существительное: без -s и без a/an.',1);
INSERT INTO "questions" VALUES(156,'Plurals & countable/uncountable nouns','grammar','A2','choice','Which word is uncountable?','egg','apple','sandwich','bread','d','Bread неисчисляемое (some bread). Egg, apple, sandwich можно посчитать: one egg, two eggs.',1);
INSERT INTO "questions" VALUES(157,'Quantifiers (some, any, much, many)','grammar','A1','choice','There are ___ apples in the bowl.','any','much','some','a little','c','В утвердительных предложениях с исчисляемыми существительными во множественном числе используется some.',1);
INSERT INTO "questions" VALUES(158,'Quantifiers (some, any, much, many)','grammar','A1','choice','Do you have ___ brothers or sisters?','some','any','a','much','b','В вопросах обычно используется any.',1);
INSERT INTO "questions" VALUES(159,'Quantifiers (some, any, much, many)','grammar','A1','choice','I don''t have ___ money.','any','some','many','a','a','В отрицательных предложениях используется any.',1);
INSERT INTO "questions" VALUES(160,'Quantifiers (some, any, much, many)','grammar','A1','choice','How ___ eggs do we need?','much','many','some','any','b','Eggs — исчисляемое существительное, поэтому how many.',1);
INSERT INTO "questions" VALUES(161,'Quantifiers (some, any, much, many)','grammar','A1','choice','How ___ milk is there in the fridge?','much','many','some','a few','a','Milk — неисчисляемое существительное, поэтому how much.',1);
INSERT INTO "questions" VALUES(162,'Quantifiers (some, any, much, many)','grammar','A2','choice','We don''t have ___ time. Hurry up!','many','a few','a lot','much','d','С неисчисляемыми существительными в отрицании используется much: not much time.',1);
INSERT INTO "questions" VALUES(163,'Quantifiers (some, any, much, many)','grammar','A2','choice','There are only ___ people at the party. It''s almost empty.','a little','much','a few','any','c','A few — «несколько» с исчисляемыми существительными; a little — с неисчисляемыми.',1);
INSERT INTO "questions" VALUES(164,'Quantifiers (some, any, much, many)','grammar','A2','choice','She eats ___ vegetables every day.','much','a little','any','a lot of','d','В утвердительных предложениях вместо much/many обычно используется a lot of.',1);
INSERT INTO "questions" VALUES(165,'Pronouns & possessives','grammar','A1','choice','___ name is Anna.','Me','My','I','Mine','b','Перед существительным используется притяжательное местоимение my.',1);
INSERT INTO "questions" VALUES(166,'Pronouns & possessives','grammar','A1','choice','Can you help ___, please?','I','my','me','mine','c','После глагола используется объектное местоимение: help me.',1);
INSERT INTO "questions" VALUES(167,'Pronouns & possessives','grammar','A1','choice','This is Tom. ___ is my brother.','He','His','Him','She','a','Подлежащее для мужского рода — he.',1);
INSERT INTO "questions" VALUES(168,'Pronouns & possessives','grammar','A1','choice','That''s Maria''s bag. It''s ___ bag.','she','hers','her','his','c','Притяжательное местоимение для she — her; оно стоит перед существительным.',1);
INSERT INTO "questions" VALUES(169,'Pronouns & possessives','grammar','A1','choice','We love ___ new house.','we','us','ours','our','d','Перед существительным используется притяжательное местоимение our.',1);
INSERT INTO "questions" VALUES(170,'Pronouns & possessives','grammar','A1','text','They love ___ cat. (they)','','','','','their','Притяжательное местоимение для they — their.',1);
INSERT INTO "questions" VALUES(171,'Pronouns & possessives','grammar','A1','choice','Whose bag is this? — It''s ___.','Tom''s','Tom','Toms','Toms''','a','Принадлежность выражается с помощью ''s: Tom''s.',1);
INSERT INTO "questions" VALUES(172,'Pronouns & possessives','grammar','A2','choice','This is not my pen. ___ is on the desk.','My','Mine','Me','I','b','Mine = my pen: притяжательное местоимение, которое стоит без существительного.',1);
INSERT INTO "questions" VALUES(173,'There is / There are','grammar','A1','choice','There ___ a cat on the sofa.','are','is','am','be','b','Существительное в единственном числе: there is.',1);
INSERT INTO "questions" VALUES(174,'There is / There are','grammar','A1','choice','There ___ two chairs in the room.','is','be','has','are','d','Существительное во множественном числе: there are.',1);
INSERT INTO "questions" VALUES(175,'There is / There are','grammar','A1','choice','___ there a bank near here?','Is','Are','Do','Does','a','Вопрос с существительным в единственном числе: Is there a ...?',1);
INSERT INTO "questions" VALUES(176,'There is / There are','grammar','A1','choice','There ___ any milk in the fridge.','aren''t','doesn''t','isn''t','hasn''t','c','Milk — неисчисляемое существительное: there isn''t any milk.',1);
INSERT INTO "questions" VALUES(177,'There is / There are','grammar','A1','text','There ___ a lot of books on the shelf. (be)','','','','','are','A lot of books — множественное число: there are.',1);
INSERT INTO "questions" VALUES(178,'There is / There are','grammar','A2','choice','There ___ some water on the floor.','is','are','has','have','a','Water — неисчисляемое существительное: there is some water.',1);
INSERT INTO "questions" VALUES(179,'There is / There are','grammar','A2','choice','There ___ a big storm last night.','is','were','was','has','c','Прошедшее время от there is — there was.',1);
INSERT INTO "questions" VALUES(180,'There is / There are','grammar','A2','choice','Which sentence is correct?','There isn''t any shops in my street.','There don''t have any shops in my street.','It hasn''t any shops in my street.','There aren''t any shops in my street.','d','Множественное число: there aren''t any. Конструкция there is/are не используется с do или have.',1);
INSERT INTO "questions" VALUES(181,'Question words & question forms','grammar','A1','choice','___ is your name?','Who','What','Where','When','b','What спрашивает о предмете или имени: What is your name?',1);
INSERT INTO "questions" VALUES(182,'Question words & question forms','grammar','A1','choice','___ do you live? — In Berlin.','When','Who','Why','Where','d','Where спрашивает о месте.',1);
INSERT INTO "questions" VALUES(183,'Question words & question forms','grammar','A1','choice','___ is that woman? — She is my teacher.','What','Which','Who','Where','c','Who спрашивает о человеке.',1);
INSERT INTO "questions" VALUES(184,'Question words & question forms','grammar','A1','choice','___ are you late? — Because I missed the bus.','Why','How','What','Who','a','Why спрашивает о причине, ответ начинается с because.',1);
INSERT INTO "questions" VALUES(185,'Question words & question forms','grammar','A1','choice','How ___ are you? — I''m twelve.','much','old','many','long','b','How old — вопрос о возрасте.',1);
INSERT INTO "questions" VALUES(186,'Question words & question forms','grammar','A2','choice','___ coat is this? — It''s Peter''s.','Who''s','Who','What','Whose','d','Whose спрашивает о принадлежности.',1);
INSERT INTO "questions" VALUES(187,'Question words & question forms','grammar','A2','choice','Which question is correct?','Where she works?','Where does she work?','Where does she works?','Where she does work?','b','После вопросительного слова идёт вспомогательный глагол, затем подлежащее: Where does she work?',1);
INSERT INTO "questions" VALUES(188,'Question words & question forms','grammar','A2','choice','How ___ is it from here to the station? — About two kilometres.','tall','much','far','old','c','How far спрашивает о расстоянии.',1);
INSERT INTO "questions" VALUES(189,'Imperatives & suggestions (let''s)','grammar','A1','choice','___ the door, please. It''s cold.','Close','Closing','To close','Closes','a','В повелительном наклонении глагол стоит в начальной форме без to.',1);
INSERT INTO "questions" VALUES(190,'Imperatives & suggestions (let''s)','grammar','A1','choice','___ late for school!','Not be','Be not','Aren''t','Don''t be','d','Отрицательное повелительное наклонение: Don''t + глагол.',1);
INSERT INTO "questions" VALUES(191,'Imperatives & suggestions (let''s)','grammar','A1','choice','___ go to the cinema tonight!','Let''s','Let','Lets','Letting','a','Let''s + глагол — предложение сделать что-то вместе.',1);
INSERT INTO "questions" VALUES(192,'Imperatives & suggestions (let''s)','grammar','A1','choice','Don''t ___ in the library. Be quiet.','talking','talk','to talk','talks','b','После Don''t глагол стоит в начальной форме.',1);
INSERT INTO "questions" VALUES(193,'Imperatives & suggestions (let''s)','grammar','A1','text','Please ___ me your phone number. (give)','','','','','give','В повелительном наклонении глагол стоит в начальной форме.',1);
INSERT INTO "questions" VALUES(194,'Imperatives & suggestions (let''s)','grammar','A1','choice','___ careful with the hot water!','Are','Is','Be','Do','c','Повелительное наклонение от to be — Be: Be careful!',1);
INSERT INTO "questions" VALUES(195,'Imperatives & suggestions (let''s)','grammar','A2','choice','How about ___ to the cinema?','go','to go','goes','going','d','После How about используется глагол с -ing.',1);
INSERT INTO "questions" VALUES(196,'Imperatives & suggestions (let''s)','grammar','A2','choice','Which sentence is correct?','Don''t open the window, it''s cold.','Not open the window, it''s cold.','Don''t to open the window, it''s cold.','Doesn''t open the window, it''s cold.','a','Отрицательное повелительное наклонение: Don''t + глагол без to.',1);
INSERT INTO "questions" VALUES(197,'Prepositions of place & movement','grammar','A1','choice','There is a picture ___ the wall.','in','on','at','to','b','Предмет находится на поверхности: on the wall.',1);
INSERT INTO "questions" VALUES(198,'Prepositions of place & movement','grammar','A1','choice','The ball is ___ the chair. (below)','on','between','under','behind','c','Under — под.',1);
INSERT INTO "questions" VALUES(199,'Prepositions of place & movement','grammar','A1','choice','The bank is ___ the post office and the cinema. (in the middle)','behind','under','between','on','c','Between — между двумя объектами.',1);
INSERT INTO "questions" VALUES(200,'Prepositions of place & movement','grammar','A1','choice','She is standing ___ the bus stop.','on','at','in','to','b','At — в определённой точке: at the bus stop.',1);
INSERT INTO "questions" VALUES(201,'Prepositions of place & movement','grammar','A1','choice','We go ___ school by bus.','to','at','in','on','a','Для движения к месту после go используется to.',1);
INSERT INTO "questions" VALUES(202,'Prepositions of place & movement','grammar','A1','choice','Where are you from? — I''m ___ Rome.','to','at','on','from','d','Be from — быть родом откуда-то.',1);
INSERT INTO "questions" VALUES(203,'Prepositions of place & movement','grammar','A2','choice','Our flat is ___ the third floor.','in','at','on','to','c','С этажами используется on: on the third floor.',1);
INSERT INTO "questions" VALUES(204,'Prepositions of place & movement','grammar','A2','choice','The café is ___ the bank. They are on different sides of the street.','between','opposite','behind','under','b','Opposite — напротив.',1);
INSERT INTO "questions" VALUES(205,'Prepositions of time (in/on/at)','grammar','A1','choice','The film starts ___ 8 o''clock.','in','on','to','at','d','At — с точным временем: at 8 o''clock.',1);
INSERT INTO "questions" VALUES(206,'Prepositions of time (in/on/at)','grammar','A1','choice','My birthday is ___ July.','in','on','at','to','a','In — с месяцами, годами, временами года.',1);
INSERT INTO "questions" VALUES(207,'Prepositions of time (in/on/at)','grammar','A1','text','We have English ___ Monday. (in / on / at)','','','','','on','On — с днями недели.',1);
INSERT INTO "questions" VALUES(208,'Prepositions of time (in/on/at)','grammar','A1','choice','I usually read ___ the evening.','on','at','to','in','d','In the morning/afternoon/evening — устойчивое выражение.',1);
INSERT INTO "questions" VALUES(209,'Prepositions of time (in/on/at)','grammar','A1','choice','He goes to bed ___ night.','in','at','on','by','b','At night — устойчивое выражение.',1);
INSERT INTO "questions" VALUES(210,'Prepositions of time (in/on/at)','grammar','A2','choice','My sister was born ___ 2010.','in','on','at','from','a','In — с годами.',1);
INSERT INTO "questions" VALUES(211,'Prepositions of time (in/on/at)','grammar','A2','choice','We play football ___ Saturday morning.','in','at','on','by','c','On — с конкретным днём, включая часть дня: on Saturday morning.',1);
INSERT INTO "questions" VALUES(212,'Prepositions of time (in/on/at)','grammar','A2','choice','I''m at school ___ 8 am to 3 pm.','since','from','in','at','b','Конструкция from ... to ... означает «с ... до ...».',1);
INSERT INTO "questions" VALUES(213,'Adverbs (frequency, manner)','grammar','A1','choice','I ___ eat meat. I''m a vegetarian.','always','often','usually','never','d','Never — никогда.',1);
INSERT INTO "questions" VALUES(214,'Adverbs (frequency, manner)','grammar','A1','choice','Tom ___ plays tennis on Saturdays. He plays every Saturday.','always','never','sometimes','hardly ever','a','Always — всегда, каждый раз.',1);
INSERT INTO "questions" VALUES(215,'Adverbs (frequency, manner)','grammar','A1','choice','___ do you go swimming? — Twice a week.','How long','How much','How often','How many','c','How often спрашивает о частоте.',1);
INSERT INTO "questions" VALUES(216,'Adverbs (frequency, manner)','grammar','A1','choice','He speaks English very ___.','good','goodly','well','nice','c','Прилагательному good соответствует наречие well.',1);
INSERT INTO "questions" VALUES(217,'Adverbs (frequency, manner)','grammar','A1','choice','She sings ___. Everyone loves her voice.','beautiful','beautifully','beauty','more beautiful','b','Наречие образуется от прилагательного с помощью -ly: beautiful → beautifully.',1);
INSERT INTO "questions" VALUES(218,'Adverbs (frequency, manner)','grammar','A2','choice','He drives very ___. He had three accidents last year.','bad','bads','worse','badly','d','Глагол определяется наречием: bad → badly.',1);
INSERT INTO "questions" VALUES(219,'Adverbs (frequency, manner)','grammar','A2','text','Write the adverb: happy → ___','','','','','happily','Если слово заканчивается на согласная + y, то y меняется на i и добавляется -ly: happy → happily.',1);
INSERT INTO "questions" VALUES(220,'Adverbs (frequency, manner)','grammar','A2','choice','I ___ go to the gym. Only once or twice a year.','hardly ever','always','usually','often','a','Hardly ever — почти никогда.',1);
INSERT INTO "questions" VALUES(221,'Modal verbs & would like','grammar','A1','choice','I ___ like a cup of tea, please.','want','am','would','have','c','Would like — вежливая просьба или пожелание.',1);
INSERT INTO "questions" VALUES(222,'Modal verbs & would like','grammar','A1','choice','___ you like some coffee? — Yes, please.','Would','Do','Are','Will','a','Would you like ...? — вежливое предложение.',1);
INSERT INTO "questions" VALUES(223,'Modal verbs & would like','grammar','A2','choice','You ___ wear a seat belt in a car. It''s the law.','might','could','would','must','d','Must — обязанность, закон.',1);
INSERT INTO "questions" VALUES(224,'Modal verbs & would like','grammar','A2','choice','You ___ park here. It''s forbidden.','don''t have to','mustn''t','should','can','b','Mustn''t — запрет.',1);
INSERT INTO "questions" VALUES(225,'Modal verbs & would like','grammar','A2','choice','Tomorrow is a holiday. You ___ get up early.','don''t have to','mustn''t','can''t','must','a','Don''t have to — нет необходимости, но и запрета нет.',1);
INSERT INTO "questions" VALUES(226,'Modal verbs & would like','grammar','A2','choice','I have a headache. — You ___ see a doctor.','shouldn''t','mustn''t','should','can''t','c','Should — совет.',1);
INSERT INTO "questions" VALUES(227,'Modal verbs & would like','grammar','A2','choice','Could you ___ me the way to the station, please?','telling','to tell','told','tell','d','После could глагол стоит в начальной форме.',1);
INSERT INTO "questions" VALUES(228,'Modal verbs & would like','grammar','A2','choice','Which sentence is correct?','He must to wear a uniform at school.','He has to wear a uniform at school.','He have to wear a uniform at school.','He has wear a uniform at school.','b','С he/she/it используется has to + глагол. После must частица to не нужна.',1);
INSERT INTO "questions" VALUES(229,'Verb patterns (to + verb, -ing)','grammar','A1','choice','I want ___ a new phone.','buy','to buy','buying','buys','b','После want используется to + глагол.',1);
INSERT INTO "questions" VALUES(230,'Verb patterns (to + verb, -ing)','grammar','A1','choice','She likes ___ books.','read','reads','reading','to reads','c','После like можно использовать глагол с -ing.',1);
INSERT INTO "questions" VALUES(231,'Verb patterns (to + verb, -ing)','grammar','A2','choice','We enjoy ___ in the sea.','swimming','to swim','swim','swims','a','После enjoy используется глагол с -ing.',1);
INSERT INTO "questions" VALUES(232,'Verb patterns (to + verb, -ing)','grammar','A2','choice','He needs ___ his homework before dinner.','finish','finishing','finishes','to finish','d','После need используется to + глагол.',1);
INSERT INTO "questions" VALUES(233,'Verb patterns (to + verb, -ing)','grammar','A2','choice','They hope ___ a good result.','getting','get','to get','gets','c','После hope используется to + глагол.',1);
INSERT INTO "questions" VALUES(234,'Verb patterns (to + verb, -ing)','grammar','A2','choice','She hates ___ up early.','getting','get','gets','got','a','После hate можно использовать глагол с -ing.',1);
INSERT INTO "questions" VALUES(235,'Verb patterns (to + verb, -ing)','grammar','A2','choice','I''m good at ___ pictures.','draw','to draw','draws','drawing','d','После предлога используется глагол с -ing.',1);
INSERT INTO "questions" VALUES(236,'Verb patterns (to + verb, -ing)','grammar','A2','text','I enjoy ___ to music. (listen)','','','','','listening','После enjoy используется глагол с -ing: listening.',1);
INSERT INTO "questions" VALUES(237,'Past Continuous','grammar','A2','choice','At eight o''clock yesterday I ___ breakfast.','am having','was having','have had','had was','b','Действие в процессе в определённый момент в прошлом: was/were + глагол с -ing.',1);
INSERT INTO "questions" VALUES(238,'Past Continuous','grammar','A2','choice','They ___ football when it started to rain.','was playing','were playing','are playing','plays','b','Они играли (действие в процессе), когда его прервал дождь: were + -ing.',1);
INSERT INTO "questions" VALUES(239,'Past Continuous','grammar','A2','choice','I ___ TV when you called me.','were watching','am watching','watch','was watching','d','С I используется was; действие было в процессе, когда позвонили.',1);
INSERT INTO "questions" VALUES(240,'Past Continuous','grammar','A2','choice','What ___ you doing at nine last night?','were','was','did','are','a','С you в Past Continuous используется were.',1);
INSERT INTO "questions" VALUES(241,'Past Continuous','grammar','A2','text','They ___ watching TV at nine o''clock. (was / were)','','','','','were','С they в Past Continuous используется were.',1);
INSERT INTO "questions" VALUES(242,'Past Continuous','grammar','A2','choice','He ___ sleeping. He was watching a film.','weren''t','isn''t','wasn''t','didn''t','c','Отрицание в Past Continuous: wasn''t/weren''t + глагол с -ing.',1);
INSERT INTO "questions" VALUES(243,'Past Continuous','grammar','A2','choice','While I ___ dinner, the phone rang.','was cooking','were cooking','am cooking','cooks','a','Длительное действие, которое прервало другое действие: was + -ing.',1);
INSERT INTO "questions" VALUES(244,'Past Continuous','grammar','A2','choice','Which sentence is correct?','We walking home when we saw an accident.','We was walking home when we saw an accident.','We were walking home when we saw an accident.','We were walk home when we saw an accident.','c','Past Continuous: was/were + глагол с -ing; с we используется were.',1);
INSERT INTO "questions" VALUES(245,'Present Perfect','grammar','A2','choice','I ___ never been to London.','has','have','am','did','b','Present Perfect: have/has + третья форма глагола.',1);
INSERT INTO "questions" VALUES(246,'Present Perfect','grammar','A2','choice','She ___ just finished her homework.','have','is','did','has','d','С she используется has: has just finished.',1);
INSERT INTO "questions" VALUES(247,'Present Perfect','grammar','A2','choice','Have you ever ___ sushi?','ate','eat','eating','eaten','d','В Present Perfect нужна третья форма глагола: eat – ate – eaten.',1);
INSERT INTO "questions" VALUES(248,'Present Perfect','grammar','A2','choice','We have lived here ___ 2015.','since','for','from','in','a','Since указывает на момент начала действия.',1);
INSERT INTO "questions" VALUES(249,'Present Perfect','grammar','A2','choice','He has worked here ___ five years.','since','for','from','in','b','For используется с периодом времени.',1);
INSERT INTO "questions" VALUES(250,'Present Perfect','grammar','A2','choice','I haven''t finished my project ___. I need more time.','already','ever','yet','just','c','Yet используется в отрицаниях и вопросах, обычно в конце предложения.',1);
INSERT INTO "questions" VALUES(251,'Present Perfect','grammar','A2','text','Write the past participle: see → ___','','','','','seen','See – saw – seen.',1);
INSERT INTO "questions" VALUES(252,'Present Perfect','grammar','A2','choice','We ___ to Paris last summer.','have gone','have been','went','go','c','С last summer (конкретное время в прошлом) используется Past Simple.',1);
INSERT INTO "questions" VALUES(253,'Future (will, going to)','grammar','A1','choice','I ___ going to visit my grandma tomorrow.','is','am','are','be','b','Be going to: I am going to + глагол.',1);
INSERT INTO "questions" VALUES(254,'Future (will, going to)','grammar','A2','choice','Look at those black clouds! It ___ rain.','is going to','will to','going to','is go to','a','Be going to используется, когда по признакам что-то скоро произойдёт.',1);
INSERT INTO "questions" VALUES(255,'Future (will, going to)','grammar','A2','choice','The phone is ringing. — I ___ answer it.','am going','go','did','will','d','Will используется для решения, принятого в момент речи.',1);
INSERT INTO "questions" VALUES(256,'Future (will, going to)','grammar','A2','choice','I think it ___ be sunny tomorrow.','am','does','will','has','c','Will используется для предположений о будущем.',1);
INSERT INTO "questions" VALUES(257,'Future (will, going to)','grammar','A2','choice','We ___ to the cinema on Saturday. We''ve already bought the tickets.','went','are going','have gone','going','b','Заранее спланированное действие: are going (Present Continuous) или be going to.',1);
INSERT INTO "questions" VALUES(258,'Future (will, going to)','grammar','A2','choice','Which sentence is correct?','She doesn''t going to come to the party.','She not going to come to the party.','She isn''t go to come to the party.','She isn''t going to come to the party.','d','Отрицание: isn''t + going to + глагол.',1);
INSERT INTO "questions" VALUES(259,'Future (will, going to)','grammar','A2','choice','___ you going to buy a new phone?','Are','Do','Will','Is','a','Вопрос с be going to: Are you going to ...?',1);
INSERT INTO "questions" VALUES(260,'Future (will, going to)','grammar','A2','choice','I promise I ___ be late again.','won''t','don''t','am not','wasn''t','a','Won''t (will not) используется для обещаний.',1);
INSERT INTO "questions" VALUES(261,'Conditionals (zero & first)','grammar','A2','choice','If it rains, we ___ at home.','would stay','will stay','stayed','stays','b','Первое условное: if + Present Simple, will + глагол.',1);
INSERT INTO "questions" VALUES(262,'Conditionals (zero & first)','grammar','A2','choice','If you heat ice, it ___.','melted','melting','melts','melt','c','Нулевое условное (общеизвестный факт): if + Present Simple, Present Simple.',1);
INSERT INTO "questions" VALUES(263,'Conditionals (zero & first)','grammar','A2','choice','If I ___ time tomorrow, I''ll call you.','will have','had','am having','have','d','После if будущее время не используется: if I have.',1);
INSERT INTO "questions" VALUES(264,'Conditionals (zero & first)','grammar','A2','choice','She will be late if she ___ the bus.','will miss','misses','missed','would miss','b','После if используется Present Simple: if she misses.',1);
INSERT INTO "questions" VALUES(265,'Conditionals (zero & first)','grammar','A2','choice','If you don''t study, you ___ the exam.','won''t pass','wouldn''t pass','didn''t pass','aren''t pass','a','Первое условное: won''t + глагол в главной части.',1);
INSERT INTO "questions" VALUES(266,'Conditionals (zero & first)','grammar','A2','text','If it ___ tomorrow, we will stay at home. (rain)','','','','','rains','После if используется Present Simple: it rains.',1);
INSERT INTO "questions" VALUES(267,'Conditionals (zero & first)','grammar','A2','choice','Which sentence is correct?','If she will come, I will be happy.','If she comes, I am be happy.','If she come, I will be happy.','If she comes, I will be happy.','d','После if используется Present Simple, а не will. С she нужно -s: comes.',1);
INSERT INTO "questions" VALUES(268,'Conditionals (zero & first)','grammar','A2','choice','What happens if you mix red and blue? — You ___ purple.','will to get','got','get','getting','c','Общеизвестный факт выражается Present Simple: you get.',1);
INSERT INTO "questions" VALUES(269,'Linking words (and, but, or, so, because)','grammar','A1','choice','I like tea ___ coffee.','but','and','so','because','b','And соединяет однородные предметы.',1);
INSERT INTO "questions" VALUES(270,'Linking words (and, but, or, so, because)','grammar','A1','choice','It''s sunny, ___ it''s cold.','or','so','but','because','c','But показывает контраст.',1);
INSERT INTO "questions" VALUES(271,'Linking words (and, but, or, so, because)','grammar','A1','choice','Do you want tea ___ coffee?','or','and','but','so','a','Or используется для выбора.',1);
INSERT INTO "questions" VALUES(272,'Linking words (and, but, or, so, because)','grammar','A1','choice','I''m hungry, ___ I''m going to make a sandwich.','because','but','or','so','d','So показывает результат («поэтому»).',1);
INSERT INTO "questions" VALUES(273,'Linking words (and, but, or, so, because)','grammar','A1','text','I stay at home ___ it''s cold. (because / so)','','','','','because','Because вводит причину.',1);
INSERT INTO "questions" VALUES(274,'Linking words (and, but, or, so, because)','grammar','A2','choice','He was ill, ___ he went to school.','so','because','or','but','d','But показывает противоположность: был болен, но всё равно пошёл в школу.',1);
INSERT INTO "questions" VALUES(275,'Linking words (and, but, or, so, because)','grammar','A2','choice','Brush your teeth ___ you go to bed.','before','because','but','so','a','Before — перед тем как.',1);
INSERT INTO "questions" VALUES(276,'Linking words (and, but, or, so, because)','grammar','A2','choice','I listen to music ___ I do my homework.','because','while','but','so','b','While — в то время как (два действия происходят одновременно).',1);
INSERT INTO "questions" VALUES(277,'Family & friends','vocabulary','A1','choice','My mother''s mother is my ___.','aunt','cousin','grandmother','niece','c','Grandmother — бабушка.',1);
INSERT INTO "questions" VALUES(278,'Family & friends','vocabulary','A1','choice','My uncle''s son is my ___.','brother','nephew','cousin','grandson','c','Cousin — двоюродный брат (или сестра).',1);
INSERT INTO "questions" VALUES(279,'Family & friends','vocabulary','A1','text','My father''s sister is my ___. (a___)','','','','','aunt','Aunt — тётя.',1);
INSERT INTO "questions" VALUES(280,'Family & friends','vocabulary','A1','choice','Tom and Sue are married. Tom is Sue''s ___.','wife','brother','father','husband','d','Husband — муж, wife — жена.',1);
INSERT INTO "questions" VALUES(281,'Family & friends','vocabulary','A2','choice','My sister''s daughter is my ___.','niece','nephew','cousin','aunt','a','Niece — племянница, nephew — племянник.',1);
INSERT INTO "questions" VALUES(282,'Family & friends','vocabulary','A2','choice','A person who lives next to you is your ___.','stranger','neighbour','colleague','relative','b','Neighbour — сосед.',1);
INSERT INTO "questions" VALUES(283,'Numbers, dates & time','vocabulary','A1','choice','Which number is 15?','fifteen','fifty','five','fourteen','a','Fifteen = 15, fifty = 50. Окончание -teen (13–19) и -ty (20, 30, ...) легко перепутать.',1);
INSERT INTO "questions" VALUES(284,'Numbers, dates & time','vocabulary','A1','choice','Which day comes after Wednesday?','Tuesday','Thursday','Friday','Saturday','b','Порядок дней: Monday, Tuesday, Wednesday, Thursday, Friday.',1);
INSERT INTO "questions" VALUES(285,'Numbers, dates & time','vocabulary','A1','text','Write the number in words: 13 → ___ (t_______)','','','','','thirteen','13 — thirteen (не путать с thirty — 30).',1);
INSERT INTO "questions" VALUES(286,'Numbers, dates & time','vocabulary','A1','choice','It''s 7:30. We say: It''s half ___ seven.','to','in','on','past','d','Half past seven — половина восьмого (7:30).',1);
INSERT INTO "questions" VALUES(287,'Numbers, dates & time','vocabulary','A2','choice','December is the ___ month of the year.','twelve','twelveth','twelfth','second','c','Порядковое числительное от twelve — twelfth.',1);
INSERT INTO "questions" VALUES(288,'Numbers, dates & time','vocabulary','A2','choice','How do you say the date 5 March?','the five of March','the fifth of March','the fiveth of March','the fifth March','b','Даты читаются порядковыми числительными: the fifth of March.',1);
INSERT INTO "questions" VALUES(289,'Food & drink','vocabulary','A1','choice','Which word is a fruit?','carrot','onion','potato','banana','d','Banana — банан (фрукт). Carrot, onion, potato — овощи.',1);
INSERT INTO "questions" VALUES(290,'Food & drink','vocabulary','A1','choice','Which word is a drink?','juice','bread','cheese','rice','a','Juice — сок.',1);
INSERT INTO "questions" VALUES(291,'Food & drink','vocabulary','A1','choice','We eat soup with a ___.','knife','fork','spoon','plate','c','Spoon — ложка.',1);
INSERT INTO "questions" VALUES(292,'Food & drink','vocabulary','A1','text','Breakfast, lunch and ___ are three meals of the day. (d_____)','','','','','dinner','Dinner — ужин (основной вечерний приём пищи).',1);
INSERT INTO "questions" VALUES(293,'Food & drink','vocabulary','A2','choice','In a restaurant, you ask for the ___ to see the list of food.','bill','tip','menu','order','c','Menu — меню.',1);
INSERT INTO "questions" VALUES(294,'Food & drink','vocabulary','A2','choice','When you finish eating in a restaurant, you ask for the ___.','menu','bill','order','tip','b','Bill — счёт.',1);
INSERT INTO "questions" VALUES(295,'Clothes & colours','vocabulary','A1','choice','If you mix blue and yellow, you get ___.','purple','orange','brown','green','d','Blue + yellow = green (зелёный).',1);
INSERT INTO "questions" VALUES(296,'Clothes & colours','vocabulary','A1','choice','You wear ___ on your feet.','shoes','gloves','hats','scarves','a','Shoes — обувь.',1);
INSERT INTO "questions" VALUES(297,'Clothes & colours','vocabulary','A1','choice','The colour of snow is ___.','white','black','red','grey','a','White — белый.',1);
INSERT INTO "questions" VALUES(298,'Clothes & colours','vocabulary','A1','text','You wear a ___ on your head. (h__)','','','','','hat','Hat — шляпа, шапка.',1);
INSERT INTO "questions" VALUES(299,'Clothes & colours','vocabulary','A2','choice','It''s cold and snowy. Put on your ___ and gloves.','shorts','sandals','scarf','T-shirt','c','Scarf — шарф.',1);
INSERT INTO "questions" VALUES(300,'Clothes & colours','vocabulary','A2','choice','This jacket is too small. Can I try a bigger ___?','colour','price','shape','size','d','Size — размер.',1);
INSERT INTO "questions" VALUES(301,'House & home','vocabulary','A1','choice','You sleep in the ___.','kitchen','bedroom','bathroom','garden','b','Bedroom — спальня.',1);
INSERT INTO "questions" VALUES(302,'House & home','vocabulary','A1','choice','You cook in the ___.','bedroom','garage','hall','kitchen','d','Kitchen — кухня.',1);
INSERT INTO "questions" VALUES(303,'House & home','vocabulary','A1','choice','You watch TV and relax on the ___.','fridge','sofa','cooker','shower','b','Sofa — диван.',1);
INSERT INTO "questions" VALUES(304,'House & home','vocabulary','A1','text','You wash your hands in the ___. (b_______)','','','','','bathroom','Bathroom — ванная комната.',1);
INSERT INTO "questions" VALUES(305,'House & home','vocabulary','A2','choice','We keep food cold in the ___.','oven','cupboard','fridge','dishwasher','c','Fridge — холодильник.',1);
INSERT INTO "questions" VALUES(306,'House & home','vocabulary','A2','choice','Our flat is on the top floor, so we have to climb the ___.','stairs','carpet','curtain','sofa','a','Stairs — лестница.',1);
INSERT INTO "questions" VALUES(307,'Daily routine','vocabulary','A1','choice','I ___ up at seven o''clock.','make','get','do','go','b','Get up — вставать.',1);
INSERT INTO "questions" VALUES(308,'Daily routine','vocabulary','A1','choice','I ___ a shower in the morning.','make','do','play','have','d','Have a shower — принимать душ.',1);
INSERT INTO "questions" VALUES(309,'Daily routine','vocabulary','A1','choice','I ___ my teeth after breakfast.','make','do','brush','play','c','Brush my teeth — чистить зубы.',1);
INSERT INTO "questions" VALUES(310,'Daily routine','vocabulary','A1','choice','I ___ to bed at eleven.','go','do','have','make','a','Go to bed — ложиться спать.',1);
INSERT INTO "questions" VALUES(311,'Daily routine','vocabulary','A2','choice','I ___ my homework in the afternoon.','make','play','do','have','c','Do homework — делать домашнее задание.',1);
INSERT INTO "questions" VALUES(312,'Daily routine','vocabulary','A2','text','I ___ the dishes after dinner. (w___)','','','','','wash','Wash the dishes — мыть посуду.',1);
INSERT INTO "questions" VALUES(313,'Hobbies & sport','vocabulary','A1','choice','I ___ football with my friends.','play','do','make','go','a','С играми и командными видами спорта используется play: play football.',1);
INSERT INTO "questions" VALUES(314,'Hobbies & sport','vocabulary','A1','choice','We ___ swimming on Saturdays.','play','go','make','take','b','Go + -ing — для активностей: go swimming.',1);
INSERT INTO "questions" VALUES(315,'Hobbies & sport','vocabulary','A1','choice','He likes ___ the guitar.','doing','going','making','playing','d','Play the guitar — играть на гитаре.',1);
INSERT INTO "questions" VALUES(316,'Hobbies & sport','vocabulary','A2','choice','She ___ judo. She has a black belt.','plays','does','goes','makes','b','С боевыми искусствами используется do: do judo.',1);
INSERT INTO "questions" VALUES(317,'Hobbies & sport','vocabulary','A2','choice','My hobby is ___ photos with my camera.','making','doing','having','taking','d','Take photos — фотографировать.',1);
INSERT INTO "questions" VALUES(318,'Hobbies & sport','vocabulary','A2','text','A person who plays football for a team is a football ___. (p_____)','','','','','player','Player — игрок.',1);
INSERT INTO "questions" VALUES(319,'Weather & seasons','vocabulary','A1','choice','In ___ it is very hot and sunny.','summer','winter','autumn','spring','a','Summer — лето.',1);
INSERT INTO "questions" VALUES(320,'Weather & seasons','vocabulary','A1','choice','Take an umbrella. It''s ___.','sunny','hot','raining','cold','c','Raining — идёт дождь.',1);
INSERT INTO "questions" VALUES(321,'Weather & seasons','vocabulary','A1','choice','Water becomes ice when it''s very ___.','hot','cold','warm','sunny','b','Cold — холодный.',1);
INSERT INTO "questions" VALUES(322,'Weather & seasons','vocabulary','A1','text','March, April and May are in ___. (s_____)','','','','','spring','Spring — весна.',1);
INSERT INTO "questions" VALUES(323,'Weather & seasons','vocabulary','A2','choice','There is a strong wind today. It''s very ___.','wind','windly','winds','windy','d','Windy — ветреный.',1);
INSERT INTO "questions" VALUES(324,'Weather & seasons','vocabulary','A2','choice','The sky is grey and there is no sun. It''s ___.','cloudy','clear','dry','hot','a','Cloudy — облачно.',1);
INSERT INTO "questions" VALUES(325,'Animals & nature','vocabulary','A1','choice','A ___ gives us milk.','pig','horse','cow','duck','c','Cow — корова.',1);
INSERT INTO "questions" VALUES(326,'Animals & nature','vocabulary','A1','choice','A ___ can fly.','fish','dog','bird','cat','c','Bird — птица.',1);
INSERT INTO "questions" VALUES(327,'Animals & nature','vocabulary','A1','choice','A ___ lives in water.','bird','fish','horse','rabbit','b','Fish — рыба.',1);
INSERT INTO "questions" VALUES(328,'Animals & nature','vocabulary','A1','text','The animal that says ''meow'' is a ___. (c__)','','','','','cat','Cat — кошка.',1);
INSERT INTO "questions" VALUES(329,'Animals & nature','vocabulary','A2','choice','The ___ is the biggest land animal.','elephant','giraffe','horse','bear','a','Elephant — слон.',1);
INSERT INTO "questions" VALUES(330,'Animals & nature','vocabulary','A2','choice','A ___ is a big area with a lot of trees.','river','desert','mountain','forest','d','Forest — лес.',1);
INSERT INTO "questions" VALUES(331,'Body & health','vocabulary','A1','choice','You see with your ___.','ears','nose','eyes','hands','c','Eyes — глаза.',1);
INSERT INTO "questions" VALUES(332,'Body & health','vocabulary','A1','choice','You hear with your ___.','eyes','mouth','feet','ears','d','Ears — уши.',1);
INSERT INTO "questions" VALUES(333,'Body & health','vocabulary','A1','choice','I have a ___. My head hurts.','headache','toothache','backache','stomachache','a','Headache — головная боль.',1);
INSERT INTO "questions" VALUES(334,'Body & health','vocabulary','A1','text','You have five ___ on each hand. (f______)','','','','','fingers','Fingers — пальцы на руке.',1);
INSERT INTO "questions" VALUES(335,'Body & health','vocabulary','A2','choice','I''m ill. I need to see a ___.','teacher','doctor','driver','waiter','b','Doctor — врач.',1);
INSERT INTO "questions" VALUES(336,'Body & health','vocabulary','A2','choice','Take this ___ twice a day. It will help your cough.','menu','ticket','medicine','lesson','c','Medicine — лекарство.',1);
INSERT INTO "questions" VALUES(337,'Jobs & workplaces','vocabulary','A1','choice','A ___ works in a hospital and helps ill people.','pilot','nurse','farmer','cook','b','Nurse — медсестра, медбрат.',1);
INSERT INTO "questions" VALUES(338,'Jobs & workplaces','vocabulary','A1','choice','A ___ teaches students.','driver','singer','baker','teacher','d','Teacher — учитель.',1);
INSERT INTO "questions" VALUES(339,'Jobs & workplaces','vocabulary','A1','choice','A ___ flies an aeroplane.','pilot','waiter','farmer','dentist','a','Pilot — пилот.',1);
INSERT INTO "questions" VALUES(340,'Jobs & workplaces','vocabulary','A1','text','A person who works on a farm is a ___. (f_____)','','','','','farmer','Farmer — фермер.',1);
INSERT INTO "questions" VALUES(341,'Jobs & workplaces','vocabulary','A2','choice','In a supermarket, a ___ takes your money at the till.','pilot','nurse','cashier','farmer','c','Cashier — кассир.',1);
INSERT INTO "questions" VALUES(342,'Jobs & workplaces','vocabulary','A2','choice','My dad is a ___. He fixes cars in a garage.','dentist','lawyer','designer','mechanic','d','Mechanic — автомеханик.',1);
INSERT INTO "questions" VALUES(343,'School & study','vocabulary','A1','choice','You write with a ___.','pen','ruler','bag','desk','a','Pen — ручка.',1);
INSERT INTO "questions" VALUES(344,'School & study','vocabulary','A1','choice','We have a Maths ___ at nine o''clock.','homework','lesson','uniform','break','b','Lesson — урок.',1);
INSERT INTO "questions" VALUES(345,'School & study','vocabulary','A1','choice','Open your ___ at page ten.','desks','books','pens','rulers','b','Books — книги.',1);
INSERT INTO "questions" VALUES(346,'School & study','vocabulary','A1','text','Students sit at a ___ in the classroom. (d___)','','','','','desk','Desk — парта, письменный стол.',1);
INSERT INTO "questions" VALUES(347,'School & study','vocabulary','A2','choice','I have an exam tomorrow, so I must ___ tonight.','study','play','wait','hurry','a','Study — учиться, готовиться.',1);
INSERT INTO "questions" VALUES(348,'School & study','vocabulary','A2','choice','He got a very good ___ in the test: 95 out of 100.','price','rule','subject','mark','d','Mark — оценка, балл (в британском английском).',1);
INSERT INTO "questions" VALUES(349,'Town & directions','vocabulary','A1','choice','You can buy bread at a ___.','library','museum','bakery','bank','c','Bakery — пекарня.',1);
INSERT INTO "questions" VALUES(350,'Town & directions','vocabulary','A1','choice','You borrow books from a ___.','cinema','hotel','library','bank','c','Library — библиотека.',1);
INSERT INTO "questions" VALUES(351,'Town & directions','vocabulary','A1','choice','Where can you see a film?','At the bank','At the cinema','At the pharmacy','At the station','b','Cinema — кинотеатр.',1);
INSERT INTO "questions" VALUES(352,'Town & directions','vocabulary','A1','text','Turn right or turn ___. (l___)','','','','','left','Left — налево.',1);
INSERT INTO "questions" VALUES(353,'Town & directions','vocabulary','A2','choice','Excuse me, is there a ___ near here? I need to buy some medicine.','museum','stadium','bakery','pharmacy','d','Pharmacy — аптека.',1);
INSERT INTO "questions" VALUES(354,'Town & directions','vocabulary','A2','choice','Go along this street and turn right ___ the bank.','after','between','under','in','a','Turn right after the bank — поверните направо после банка.',1);
INSERT INTO "questions" VALUES(355,'Travel & transport','vocabulary','A1','choice','A ___ goes on rails.','bus','train','taxi','bike','b','Train — поезд.',1);
INSERT INTO "questions" VALUES(356,'Travel & transport','vocabulary','A1','choice','We fly in a ___ to go abroad.','plane','train','bus','car','a','Plane — самолёт.',1);
INSERT INTO "questions" VALUES(357,'Travel & transport','vocabulary','A1','choice','I go to school ___ bus.','in','with','at','by','d','By + вид транспорта: by bus.',1);
INSERT INTO "questions" VALUES(358,'Travel & transport','vocabulary','A1','text','You buy a ___ before you travel by train. (t_____)','','','','','ticket','Ticket — билет.',1);
INSERT INTO "questions" VALUES(359,'Travel & transport','vocabulary','A2','choice','Our flight leaves at ten. We must be at the ___ at eight.','station','port','airport','bus stop','c','Airport — аэропорт.',1);
INSERT INTO "questions" VALUES(360,'Travel & transport','vocabulary','A2','choice','We booked a room in a ___ for three nights.','airport','hotel','station','restaurant','b','Hotel — гостиница.',1);
INSERT INTO "questions" VALUES(361,'Shopping & money','vocabulary','A1','choice','How ___ is this T-shirt? — It''s ten pounds.','many','long','much','old','c','How much — сколько стоит.',1);
INSERT INTO "questions" VALUES(362,'Shopping & money','vocabulary','A1','text','You can pay with cash or with a credit ___. (c___)','','','','','card','Credit card — кредитная карта.',1);
INSERT INTO "questions" VALUES(363,'Shopping & money','vocabulary','A1','choice','Shops usually ___ at nine o''clock in the morning.','cost','sell','pay','open','d','Open — открываться.',1);
INSERT INTO "questions" VALUES(364,'Shopping & money','vocabulary','A1','choice','The opposite of ''cheap'' is ___.','expensive','small','new','free','a','Expensive — дорогой.',1);
INSERT INTO "questions" VALUES(365,'Shopping & money','vocabulary','A2','choice','I paid 50 euros, but the T-shirt cost 40. The shop assistant gave me 10 euros ___.','tip','price','change','bill','c','Change — сдача.',1);
INSERT INTO "questions" VALUES(366,'Shopping & money','vocabulary','A2','choice','Can I have a ___, please? I want to return these shoes if they don''t fit.','recipe','menu','ticket','receipt','d','Receipt — чек.',1);
INSERT INTO "questions" VALUES(367,'Technology & communication','vocabulary','A1','choice','You use a ___ to type words on a computer.','printer','keyboard','speaker','battery','b','Keyboard — клавиатура.',1);
INSERT INTO "questions" VALUES(368,'Technology & communication','vocabulary','A1','text','You can look for information on the ___. (i_______)','','','','','internet','Internet — интернет.',1);
INSERT INTO "questions" VALUES(369,'Technology & communication','vocabulary','A2','choice','My phone isn''t working. The ___ is empty.','battery','charger','camera','password','a','Battery — батарея, аккумулятор.',1);
INSERT INTO "questions" VALUES(370,'Technology & communication','vocabulary','A2','choice','I can''t log in because I forgot my ___.','password','screen','printer','website','a','Password — пароль.',1);
INSERT INTO "questions" VALUES(371,'Technology & communication','vocabulary','A2','choice','To get a file from the internet to your computer, you ___ it.','upload','download','delete','print','b','Download — скачать; upload — загрузить на сайт.',1);
INSERT INTO "questions" VALUES(372,'Technology & communication','vocabulary','A2','choice','I took a ___ of the beautiful sunset with my phone.','page','game','photo','link','c','Photo — фотография.',1);
INSERT INTO "questions" VALUES(373,'Feelings & describing people','vocabulary','A1','choice','She is smiling. She is ___.','sad','angry','tired','happy','d','Happy — счастливый.',1);
INSERT INTO "questions" VALUES(374,'Feelings & describing people','vocabulary','A1','choice','He lost his dog yesterday. Now he is ___.','happy','excited','hungry','sad','d','Sad — грустный.',1);
INSERT INTO "questions" VALUES(375,'Feelings & describing people','vocabulary','A1','choice','I didn''t sleep last night. Now I''m very ___.','hungry','afraid','tired','lucky','c','Tired — уставший.',1);
INSERT INTO "questions" VALUES(376,'Feelings & describing people','vocabulary','A1','choice','The opposite of ''tall'' is ___.','short','big','long','thin','a','Short — низкий, невысокий.',1);
INSERT INTO "questions" VALUES(377,'Feelings & describing people','vocabulary','A2','choice','My brother is very ___. He always makes us laugh.','boring','funny','shy','quiet','b','Funny — смешной, весёлый.',1);
INSERT INTO "questions" VALUES(378,'Feelings & describing people','vocabulary','A2','choice','She doesn''t like talking to new people. She is ___.','friendly','shy','funny','kind','b','Shy — застенчивый.',1);
INSERT INTO "questions" VALUES(379,'Family & friends','reading','A1','choice','Read the text.
This is my family. I have a mother, a father and a sister. My sister''s name is Lily. She is ten. I am thirteen.

Question: How old is Lily?','ten','thirteen','three','twelve','a','В тексте сказано, что Lily — сестра автора и ей десять лет (thirteen — возраст автора).',1);
INSERT INTO "questions" VALUES(380,'Daily routine','reading','A1','choice','Read the text.
My name is Ben. I get up at seven o''clock. I have breakfast at half past seven. I go to school at eight o''clock and come home at four.

Question: When does Ben have breakfast?','At seven o''clock','At eight o''clock','At half past seven','At four o''clock','c','Half past seven — половина восьмого. В семь Бен встаёт, в восемь идёт в школу.',1);
INSERT INTO "questions" VALUES(381,'Food & drink','reading','A1','text','Read the text.
At the café: Tom has a sandwich and an orange juice. Kate has a salad and a tea. She doesn''t like coffee.

Question: What does Kate drink? Write one word.','','','','','tea','Kate has a salad and a tea — она пьёт чай. Orange juice пьёт Tom.',1);
INSERT INTO "questions" VALUES(382,'Weather & seasons','reading','A1','choice','Read the text.
It''s cold and rainy today. Tomorrow it will be sunny and warm, so we can go to the park.

Question: What is the weather like today?','Sunny and warm','Cold and sunny','Hot and rainy','Cold and rainy','d','Сегодня холодно и дождливо; солнечно и тепло будет только завтра.',1);
INSERT INTO "questions" VALUES(383,'House & home','reading','A1','choice','Read the text.
My flat is small. It has one bedroom, a kitchen and a bathroom. There is also a balcony with two chairs and a table. I drink my coffee there in the morning.

Question: Where does the writer drink coffee?','In the kitchen','In the bedroom','On the balcony','In the bathroom','c','Кофе автор пьёт на балконе (there = on the balcony).',1);
INSERT INTO "questions" VALUES(384,'Town & directions','reading','A1','choice','Read the text.
LIBRARY
Open: Monday to Friday, 9:00-17:00
Closed: Saturday and Sunday

Question: When is the library closed?','On Monday','On Wednesday','On Friday','On Sunday','d','Библиотека закрыта в субботу и воскресенье. Среди вариантов только Sunday.',1);
INSERT INTO "questions" VALUES(385,'Shopping & money','reading','A1','choice','Read the text.
BIG SALE!
T-shirts £5
Jeans £15
Shoes £20
Open every day, 10 am to 6 pm

Question: How much are the jeans?','£5','£15','£20','£10','b','Jeans £15. £5 — это футболки, £20 — обувь.',1);
INSERT INTO "questions" VALUES(386,'Travel & transport','reading','A1','choice','Read the text.
Train to Oxford. Leaves at 9:15 from Platform 4. Please buy your ticket before you get on the train.

Question: Which platform does the train leave from?','Platform 4','Platform 9','Platform 15','Platform 5','a','Поезд отправляется с платформы 4 (Platform 4). 9:15 — время отправления.',1);
INSERT INTO "questions" VALUES(387,'Hobbies & sport','reading','A1','choice','Read the text.
I like sport. I play football on Monday and tennis on Thursday. On Saturday I go swimming with my friend Jack.

Question: When does the writer play tennis?','On Thursday','On Monday','On Saturday','On Sunday','a','Tennis on Thursday — теннис по четвергам. В понедельник футбол, в субботу плавание.',1);
INSERT INTO "questions" VALUES(388,'Animals & nature','reading','A1','text','Read the text.
I have a pet. It''s a small white rabbit. Its name is Snowy. It eats carrots and lives in a big box in my room.

Question: What animal is Snowy? Write one word.','','','','','rabbit','Snowy — a small white rabbit, то есть кролик.',1);
INSERT INTO "questions" VALUES(389,'Clothes & colours','reading','A1','text','Read the text.
I''m going to a party tonight. I''m wearing my new blue dress and black shoes.

Question: What colour are the shoes? Write one word.','','','','','black','Black shoes — чёрные туфли. Blue — это платье.',1);
INSERT INTO "questions" VALUES(390,'Numbers, dates & time','reading','A1','choice','Read the text.
School starts at 8:45. The first lesson is Maths. Break is at 10:30, and lunch is at 12:15.

Question: What time is break?','8:45','12:15','10:15','10:30','d','Break is at 10:30. 8:45 — начало уроков, 12:15 — обед.',1);
INSERT INTO "questions" VALUES(391,'Daily routine','reading','A2','choice','Read the text.
Hi Sara,
I''m sorry, I can''t meet you at five. I have to work late today. Can we meet at seven instead? I''ll wait for you outside the cinema.
Love, Mia

Question: Why can''t Mia meet Sara at five?','She is ill','She is at the cinema','She has to work late','She is at school','c','В тексте: I have to work late today — ей нужно задержаться на работе.',1);
INSERT INTO "questions" VALUES(392,'Travel & transport','reading','A2','choice','Read the text.
We arrived at the airport at six in the morning, but our flight was late. We waited for three hours. At last, we flew to Rome and took a taxi to our hotel.

Question: How long did they wait at the airport?','Six hours','Three hours','One hour','All day','b','We waited for three hours — они ждали три часа (в шесть утра они только приехали).',1);
INSERT INTO "questions" VALUES(393,'Food & drink','reading','A2','choice','Read the text.
Lucy doesn''t eat meat or fish, but she loves vegetables and cheese. For lunch she usually has a cheese sandwich with a salad. Today she wants a pizza with mushrooms.

Question: Which food does Lucy NOT eat?','Cheese','Salad','Meat','Pizza','c','Lucy doesn''t eat meat or fish — мясо она не ест. Сыр, салат и пиццу с грибами она ест.',1);
INSERT INTO "questions" VALUES(394,'School & study','reading','A2','choice','Read the text.
Our English teacher gives us a lot of homework. Last night I wrote an essay, and it took me two hours. Tomorrow we have a test, so I''m going to study again after dinner.

Question: What is the writer going to do after dinner?','Write an essay','Go to bed','Meet a friend','Study for a test','d','I''m going to study again after dinner — автор будет готовиться к тесту. Эссе он написал вчера.',1);
INSERT INTO "questions" VALUES(395,'Weather & seasons','reading','A2','choice','Read the text.
Last week we went to Scotland. It was cold and it rained every day, but the mountains were beautiful. Next time we''ll go in summer.

Question: When will they go to Scotland next time?','In summer','In winter','Next week','Yesterday','a','Next time we''ll go in summer — в следующий раз они поедут летом.',1);
INSERT INTO "questions" VALUES(396,'Technology & communication','reading','A2','choice','Read the text.
Hi Dad,
My phone has no battery and I forgot my charger at school. Can you pick me up at the library at five? I''ll use a computer there to send you an email if there is a problem.

Question: What is the problem with the phone?','It is broken','It has no battery','It is lost','It is at school','b','My phone has no battery — телефон разряжен. Зарядку автор забыл в школе.',1);
INSERT INTO "questions" VALUES(397,'Body & health','reading','A2','choice','Read the text.
DOCTOR''S NOTICE
Please arrive ten minutes before your appointment. Bring a list of your medicines. If you can''t come, call us at least one day before.

Question: What should patients do if they can''t come?','Arrive early','Call the doctor one day before','Bring their medicines','Send an email','b','If you can''t come, call us at least one day before — нужно позвонить за день.',1);
INSERT INTO "questions" VALUES(398,'Jobs & workplaces','reading','A2','choice','Read the text.
I''m a nurse in a big hospital. I start work at seven in the morning and finish at seven in the evening, three days a week. I love my job because I help people, but it''s very tiring.

Question: What is difficult about the writer''s job?','It is boring','It is badly paid','It is dangerous','It is very tiring','d','But it''s very tiring — работа очень утомительная. О зарплате и опасности в тексте ничего нет.',1);
INSERT INTO "questions" VALUES(399,'Town & directions','reading','A2','choice','Read the text.
To get to the museum from the station, turn left and walk along Park Road for five minutes. Turn right at the bank. The museum is opposite the post office.

Question: Where is the museum?','Opposite the post office','Next to the bank','Behind the station','On the left of the station','a','The museum is opposite the post office — музей напротив почты. Банк — только ориентир для поворота.',1);
INSERT INTO "questions" VALUES(400,'Shopping & money','reading','A2','choice','Read the text.
Buy two, get one free! All T-shirts are €8 this week only. Jeans are not on sale. The shop closes at eight on Fridays.

Question: What do you get if you buy two T-shirts?','Free jeans','Half price jeans','A third T-shirt for free','A free bag','c','Buy two, get one free — при покупке двух футболок третья бесплатно. Джинсы в акции не участвуют.',1);
INSERT INTO "questions" VALUES(401,'Hobbies & sport','reading','A2','choice','Read the text.
Tom started playing the guitar two years ago. He practises for an hour every evening, and now he plays in a band with his friends. They are giving a concert on Saturday.

Question: When is the concert?','On Saturday','Two years ago','Every evening','Tomorrow','a','They are giving a concert on Saturday — концерт в субботу.',1);
INSERT INTO "questions" VALUES(402,'Family & friends','reading','A2','choice','Read the text.
My grandparents live in a small village. Every summer we stay with them for two weeks. My grandfather and I fish in the river, and my grandmother bakes delicious cakes.

Question: What do the writer and the grandfather do together?','They bake cakes','They play football','They go shopping','They fish in the river','d','My grandfather and I fish in the river — вместе они ловят рыбу. Пироги печёт бабушка.',1);
CREATE TABLE rewards (
    id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL REFERENCES users(id),
    kind TEXT NOT NULL, amount INTEGER NOT NULL, reason TEXT,
    given_by INTEGER REFERENCES users(id), ts TEXT NOT NULL);
INSERT INTO "rewards" VALUES(1,2,'xp',10,'Бонус за домашку в срок',NULL,'2026-10-25T10:01:34+00:00');
INSERT INTO "rewards" VALUES(2,3,'xp',10,'Бонус за домашку в срок',NULL,'2026-10-25T10:17:43+00:00');
INSERT INTO "rewards" VALUES(3,3,'coins',25000,'[Потому что ты самый сладкий пирожёк)))]',1,'2026-10-25T10:22:43+00:00');
INSERT INTO "rewards" VALUES(4,2,'coins',25000,'[Ты соска]',1,'2026-10-25T10:25:00+00:00');
INSERT INTO "rewards" VALUES(5,2,'coins',-25013,'Ты вдвойне сосок',1,'2026-10-25T10:26:54+00:00');
INSERT INTO "rewards" VALUES(6,3,'xp',10,'Бонус за домашку в срок',NULL,'2026-10-25T10:41:03+00:00');
INSERT INTO "rewards" VALUES(7,2,'xp',10,'Бонус за домашку в срок',NULL,'2026-10-25T10:43:05+00:00');
INSERT INTO "rewards" VALUES(8,3,'xp',10,'Бонус за домашку в срок',NULL,'2026-10-25T10:48:21+00:00');
INSERT INTO "rewards" VALUES(9,2,'xp',10,'Бонус за домашку в срок',NULL,'2026-10-25T11:52:08+00:00');
INSERT INTO "rewards" VALUES(10,3,'xp',10,'Бонус за домашку в срок',NULL,'2026-10-25T13:42:40+00:00');
INSERT INTO "rewards" VALUES(11,2,'xp',10,'Бонус за домашку в срок',NULL,'2026-10-25T13:45:49+00:00');
INSERT INTO "rewards" VALUES(12,3,'coins',-9999,'Слишком расстроена',1,'2026-10-25T14:50:07+00:00');
INSERT INTO "rewards" VALUES(13,3,'coins',9999,'За самую сочную жопку в мире🔥',1,'2026-10-25T14:54:47+00:00');
INSERT INTO "rewards" VALUES(14,5,'xp',10,'Бонус за домашку в срок',NULL,'2026-10-25T20:07:27+00:00');
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT, telegram_id INTEGER UNIQUE NOT NULL, nickname TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'student', group_id INTEGER REFERENCES groups(id),
    is_active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL);
INSERT INTO "users" VALUES(1,5423077837,'Teacher','teacher',NULL,1,'2026-10-24T19:28:13+00:00');
INSERT INTO "users" VALUES(2,1681821592,'Лилпип','student',1,1,'2026-10-24T19:32:47+00:00');
INSERT INTO "users" VALUES(3,5611522762,'Биверъ','student',1,1,'2026-10-24T19:35:08+00:00');
INSERT INTO "users" VALUES(4,1801685269,'Драйвер','student',1,1,'2026-10-25T10:14:12+00:00');
INSERT INTO "users" VALUES(5,7364176230,'ника_пр','student',2,1,'2026-10-25T12:36:08+00:00');
INSERT INTO "users" VALUES(6,5764817288,'Тима','student',3,1,'2026-10-25T13:09:44+00:00');
CREATE UNIQUE INDEX ux_users_nick ON users(nickname COLLATE NOCASE);
CREATE INDEX ix_events_user ON events(user_id, ts);
CREATE INDEX ix_events_day ON events(day);
DELETE FROM "sqlite_sequence";
INSERT INTO "sqlite_sequence" VALUES('users',6);
INSERT INTO "sqlite_sequence" VALUES('events',259);
INSERT INTO "sqlite_sequence" VALUES('cheatsheets',5);
INSERT INTO "sqlite_sequence" VALUES('homework',10);
INSERT INTO "sqlite_sequence" VALUES('groups',3);
INSERT INTO "sqlite_sequence" VALUES('rewards',14);
COMMIT;
