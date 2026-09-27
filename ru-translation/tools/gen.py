# -*- coding: utf-8 -*-
"""
Генератор SQL-файлов русификации из выгрузок HeidiSQL (1.csv..4.csv).

Запуск (из папки ru-translation):  python3 tools/gen.py
Результат: sql/02_*.sql ... sql/05_*.sql

Для каждой строки проверяется, что плейсхолдеры ({}, %u, %s, |cff..|r, $B и т.п.)
в переводе совпадают с оригиналом. Иначе сервер может упасть или вывести мусор.
"""
import csv, os, re, sys, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import tr_bots
try:
    import tr_gossip
except ImportError:
    tr_gossip = None
try:
    import tr_strings
except ImportError:
    tr_strings = None

PH = re.compile(r"\{\d*\}|%(?:\d+\$)?[-+#0]*\d*(?:\.\d+)?(?:l|ll|h|I64)?[sdiufxXcgp%]|\|c[0-9a-fA-F]{8}|\|r|\|H[^|]*\||\|h|\$[BbNnGgRrCc]|\\n|\n")

def placeholders(s):
    return collections.Counter(m.lower() if m.startswith('$') else m for m in PH.findall(s or ""))

def read_csv(name):
    path = os.path.join(ROOT, "export", name)
    rows = []
    with open(path, encoding="utf-8-sig", newline="") as f:
        for r in csv.DictReader(f):
            for k, v in r.items():
                if v == r"\N":
                    r[k] = None
                elif v is not None:
                    # HeidiSQL экранирует так: \'  \\  \n  \r  \t
                    r[k] = re.sub(r"\\(['\\nrt\"])",
                                  lambda m: {"n": "\n", "r": "\r", "t": "\t"}.get(m.group(1), m.group(1)), v)
            rows.append(r)
    return rows

def q(s):
    if s is None:
        return "NULL"
    # Апостроф удваиваем ('') — стандартный SQL, HeidiSQL его корректно разбирает
    return "'" + s.replace("\\", "\\\\").replace("'", "''").replace("\r", "\\r").replace("\n", "\\n") + "'"

ERRORS = []
MISSING = collections.defaultdict(list)

def check(kind, key, src, dst):
    if dst is None:
        return
    if placeholders(src) != placeholders(dst):
        ERRORS.append(f"[{kind} {key}] плейсхолдеры не совпадают:\n   EN: {src!r}\n   RU: {dst!r}\n"
                      f"   EN={dict(placeholders(src))} RU={dict(placeholders(dst))}")

def header(title, table):
    return (f"-- =====================================================================\n"
            f"-- {title}\n"
            f"-- База: acore_world. Таблица: {table}. Сгенерировано tools/gen.py\n"
            f"-- Перед применением остановите worldserver. Файл можно применять повторно.\n"
            f"-- =====================================================================\n"
            f"SET NAMES utf8mb4;\n\n")

def write(name, text):
    path = os.path.join(ROOT, "sql", name)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print(f"  {name}: {os.path.getsize(path)} байт")

def chunks(lst, n=200):
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

# ---------------------------------------------------------------- 1.csv
def gen_npc_text():
    rows = read_csv("1.csv")
    vals = []
    for r in rows:
        i = int(r["ID"]); src = r["text0_0"] or ""
        dst = tr_bots.NPC_TEXT.get(i)
        if dst is None:
            MISSING["npc_text"].append((i, src)); continue
        check("npc_text", i, src, dst)
        vals.append((i, dst))
    out = header("Боты NPCBots: недостающие фразы и пункты меню", "npc_text_locale")
    ids = ",".join(str(i) for i, _ in vals)
    out += f"DELETE FROM `npc_text_locale` WHERE `Locale`='ruRU' AND `ID` IN ({ids});\n"
    out += "INSERT INTO `npc_text_locale` (`ID`, `Locale`, `Text0_0`, `Text0_1`) VALUES\n"
    out += ",\n".join(f"({i}, 'ruRU', {q(t)}, {q(t)})" for i, t in vals) + ";\n"
    write("02_npcbots_npc_text_dop.sql", out)
    return len(vals), len(rows)

# ---------------------------------------------------------------- 2.csv
def bot_subname(sub):
    m = re.match(r"^(.*) [Bb]ot$", sub or "")
    if m and m.group(1) in tr_bots.BOT_CLASS:
        return tr_bots.BOT_CLASS[m.group(1)] + " (бот)"
    return None

def gen_creatures():
    rows = read_csv("2.csv")
    vals = []
    for r in rows:
        e = int(r["entry"]); name = r["name"] or ""; sub = r["subname"]
        rname = tr_bots.NAME.get(name, name)
        if sub in (None, ""):
            rsub = tr_bots.SUBNAME_BY_ENTRY.get(e)
        else:
            rsub = bot_subname(sub) or tr_bots.SUBNAME.get(sub)
            if rsub is None:
                MISSING["creature subname"].append((e, sub)); rsub = sub
        check("creature", e, sub or "", rsub or "") if sub else None
        vals.append((e, rname, rsub))
    out = header("Имена и подписи ботов, питомцев и кастомных NPC", "creature_template_locale")
    for part in chunks(vals):
        ids = ",".join(str(e) for e, _, _ in part)
        out += f"DELETE FROM `creature_template_locale` WHERE `locale`='ruRU' AND `entry` IN ({ids});\n"
        out += "INSERT INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`) VALUES\n"
        out += ",\n".join(f"({e}, 'ruRU', {q(n)}, {q(s)})" for e, n, s in part) + ";\n\n"
    write("03_suschestva_imena.sql", out)
    return len(vals), len(rows)

# ---------------------------------------------------------------- 3.csv
def gen_gossip():
    if not tr_gossip:
        return None
    rows = read_csv("3.csv")
    vals = []
    for r in rows:
        m, o = int(r["MenuID"]), int(r["OptionID"])
        t, b = r["OptionText"] or "", r["BoxText"]
        rt = tr_gossip.translate_option(t)
        if rt is None:
            MISSING["gossip"].append((m, o, t)); continue
        rb = tr_gossip.translate_box(b) if b else b
        if b and rb is None:
            MISSING["gossip box"].append((m, o, b)); rb = b
        check("gossip", f"{m}/{o}", t, rt)
        if b: check("gossip box", f"{m}/{o}", b, rb)
        vals.append((m, o, rt, rb))
    out = header("Пункты меню NPC (стандартные диалоги и телепортёр)", "gossip_menu_option_locale")
    for part in chunks(vals):
        cond = " OR ".join(f"(`MenuID`={m} AND `OptionID`={o})" for m, o, _, _ in part)
        out += f"DELETE FROM `gossip_menu_option_locale` WHERE `Locale`='ruRU' AND ({cond});\n"
        out += "INSERT INTO `gossip_menu_option_locale` (`MenuID`, `OptionID`, `Locale`, `OptionText`, `BoxText`) VALUES\n"
        out += ",\n".join(f"({m}, {o}, 'ruRU', {q(t)}, {q(b)})" for m, o, t, b in part) + ";\n\n"
    write("04_menyu_npc.sql", out)
    return len(vals), len(rows)

# ---------------------------------------------------------------- 4.csv
def gen_strings():
    if not tr_strings:
        return None
    rows = read_csv("4.csv")
    vals = []
    for r in rows:
        e = int(r["entry"]); src = r["content_default"] or ""
        dst = tr_strings.T.get(e)
        if dst is not None and "\\n" in dst and "\\n" not in src:
            dst = dst.replace("\\n", "\n")   # в оригинале настоящий перевод строки
        if dst is None:
            MISSING["acore_string"].append((e, src)); continue
        check("acore_string", e, src, dst)
        vals.append((e, dst))
    out = header("Системные сообщения сервера и ответы на команды", "acore_string")
    # Одна UPDATE-команда через временную таблицу (HeidiSQL не ругается на 1193 отдельных UPDATE)
    out += "DROP TEMPORARY TABLE IF EXISTS `tmp_ru_strings`;\n"
    out += "CREATE TEMPORARY TABLE `tmp_ru_strings` (`entry` INT UNSIGNED NOT NULL PRIMARY KEY, `txt` TEXT) DEFAULT CHARSET=utf8mb4;\n"
    for part in chunks(vals, 200):
        out += "INSERT INTO `tmp_ru_strings` (`entry`, `txt`) VALUES\n"
        out += ",\n".join(f"({e}, {q(t)})" for e, t in part) + ";\n"
    out += ("UPDATE `acore_string` AS a INNER JOIN `tmp_ru_strings` AS t ON t.`entry` = a.`entry`\n"
            "SET a.`locale_ruRU` = t.`txt` WHERE a.`entry` = t.`entry`;\n")
    out += "DROP TEMPORARY TABLE IF EXISTS `tmp_ru_strings`;\n"
    write("05_soobscheniya_servera.sql", out)
    return len(vals), len(rows)

if __name__ == "__main__":
    print("Генерация:")
    stats = {
        "1.csv фразы ботов": gen_npc_text(),
        "2.csv имена NPC": gen_creatures(),
        "3.csv меню NPC": gen_gossip(),
        "4.csv сообщения": gen_strings(),
    }
    # Общий файл: 01 (официальный перевод ботов) + 02..05
    parts = ["01_npcbots_npc_text_locale_ruRU.sql", "02_npcbots_npc_text_dop.sql", "03_suschestva_imena.sql",
             "04_menyu_npc.sql", "05_soobscheniya_servera.sql"]
    allsql = ("-- =====================================================================\n"
              "-- RUSIFIKACIYA_VSE.sql — вся русификация одним файлом (01..05).\n"
              "-- База: acore_world. Перед применением остановите worldserver и сделайте бэкап.\n"
              "-- =====================================================================\n"
              "SET NAMES utf8mb4;\n\n")
    for n in parts:
        path = os.path.join(ROOT, "sql", n)
        if os.path.exists(path):
            allsql += f"\n-- ---------------- {n} ----------------\n" + open(path, encoding="utf-8").read() + "\n"
    write("RUSIFIKACIYA_VSE.sql", allsql)

    print("\nИтог:")
    for k, v in stats.items():
        print(f"  {k}: " + ("ещё не переведено" if v is None else f"{v[0]} из {v[1]}"))
    for k, lst in MISSING.items():
        print(f"\nНет перевода ({k}): {len(lst)}")
        for x in lst[:15]:
            print("   ", x)
    if ERRORS:
        print(f"\nОШИБКИ ПЛЕЙСХОЛДЕРОВ: {len(ERRORS)}")
        for e in ERRORS[:40]:
            print(e)
        sys.exit(1)
    print("\nПроверка плейсхолдеров: OK")
