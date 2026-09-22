#!/usr/bin/env python3
#===========================================================================
# tools/audit_addons.py — аудит папки с аддонами WoW 3.3.5.
#
# Что проверяет:
#   1) .toc:            каждый указанный файл существует (с учётом регистра),
#                       нет дублей, корректный заголовок ## Interface,
#                       пути с прямыми слэшами / обратными слэшами;
#   2) .lua:            синтаксис (через tools/lua_syntax.js на Fengari);
#   3) .xml:            корректность разметки;
#   4) мусор:           .DS_Store, .git, .svn, Thumbs.db, пустые каталоги;
#   5) локализация:     есть ли ruRU (файлы localization*, locals/, ruRU);
#   6) кодировка:       UTF-8 / CP1251 — важно для русского текста.
#
# Запуск:
#   python3 tools/audit_addons.py <папка-с-аддонами> [--json отчёт.json]
#
# Пример:
#   python3 tools/audit_addons.py AddOns
#===========================================================================

import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

JUNK_NAMES = {".DS_Store", "Thumbs.db", "desktop.ini", ".git", ".svn", ".hg",
              "CVS", "__MACOSX", ".idea", ".vscode"}
JUNK_SUFFIXES = (".bak", ".orig", "~", ".tmp", ".url", ".lnk")
LOCALE_MARKERS = ("localization", "locals", "locale", "_ru", "ru-ru")


def detect_encoding(path):
    data = open(path, "rb").read()
    try:
        data.decode("utf-8")
        return "utf-8"
    except UnicodeDecodeError:
        pass
    try:
        data.decode("cp1251")
        return "cp1251"
    except UnicodeDecodeError:
        return "unknown"


CYR_RE = re.compile("[\u0400-\u04ff]")


def has_cyrillic(path, min_chars=20):
    """Есть ли в файле заметный русский текст (utf-8 или cp1251).

    Важно: декодировать cp1251 «на всякий случай» нельзя — почти любой
    байт в диапазоне 0xC0..0xFF даёт кириллицу, и тогда «русским» окажется
    каждый файл. Поэтому cp1251 проверяем только если файл не читается
    как utf-8.
    """
    try:
        raw = open(path, "rb").read(2000000)
    except OSError:
        return False
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("cp1251", errors="replace")
    return len(CYR_RE.findall(text)) >= min_chars


def parse_toc(path):
    """Разбор .toc: поля ## Ключ: значение и список файлов."""
    fields, files, problems = {}, [], []
    raw = open(path, "rb").read()

    encoding = "utf-8"
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("cp1251", errors="replace")
        encoding = "cp1251"

    # BOM в начале .toc: клиент 3.3.5 его игнорирует (так собраны многие
    # популярные аддоны, например AtlasLoot), поэтому снимаем его и мы.
    if text.startswith("\ufeff"):
        problems.append(("info", 0, "BOM в начале .toc — клиент это допускает"))
        text = text.lstrip("\ufeff")

    for lineno, line in enumerate(text.splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("##"):
            body = line[2:].strip()
            if ":" in body:
                key, value = body.split(":", 1)
                fields[key.strip().lower()] = value.strip()
            else:
                problems.append(("warn", lineno, "непонятный заголовок: " + line[:60]))
            continue
        files.append((lineno, line))

    return fields, files, problems, encoding


def check_addon(addon_dir):
    """Проверить один аддон. Возвращает словарь с результатом."""
    name = os.path.basename(addon_dir)
    result = {
        "name": name,
        "path": addon_dir,
        "toc": None,
        "interface": None,
        "title": None,
        "version": None,
        "encoderu": None,
        "files_listed": 0,
        "missing_files": [],
        "case_mismatch": [],
        "duplicate_entries": [],
        "lua_files": 0,
        "lua_errors": [],
        "xml_files": 0,
        "xml_errors": [],
        "junk": [],
        "empty_dirs": [],
        "has_ru": False,
        "ru_files": [],
        "ru_text_files": [],
        "encodings": {},
        "notes": [],
    }

    # ---- .toc ----
    tocs = sorted(f for f in os.listdir(addon_dir) if f.lower().endswith(".toc"))
    if not tocs:
        # бывает: .toc лежит с другим именем, чем папка
        nested = []
        for root, dirs, files in os.walk(addon_dir):
            for f in files:
                if f.lower().endswith(".toc"):
                    nested.append(os.path.join(root, f))
        if nested:
            result["notes"].append("нет .toc в корне, найден глубже: "
                                   + ", ".join(os.path.relpath(n, addon_dir) for n in nested[:3]))
        else:
            result["notes"].append("нет .toc — аддон не загрузится клиентом")
        toc_path = None
    else:
        toc_path = os.path.join(addon_dir, tocs[0])
        result["toc"] = tocs[0]
        if len(tocs) > 1:
            result["notes"].append("несколько .toc: " + ", ".join(tocs))

    if toc_path:
        fields, files, problems, enc = parse_toc(toc_path)
        result["interface"] = fields.get("interface")
        result["title"] = fields.get("title")
        result["version"] = fields.get("version")
        result["encoderu"] = fields.get("x-encoderu") or fields.get("x-encoding")
        result["files_listed"] = len(files)
        for kind, lineno, msg in problems:
            if kind == "info":
                result["notes"].append(msg)
            else:
                result["notes"].append("toc:%d %s" % (lineno, msg))

        # регистр имён: файловая система Linux чувствительна, клиент — нет.
        # Поэтому сверяем с реальным деревом в нижнем регистре.
        real = {}
        for root, dirs, fs in os.walk(addon_dir):
            for f in fs:
                rel = os.path.relpath(os.path.join(root, f), addon_dir)
                real[rel.replace("\\", "/").lower()] = rel

        seen = {}
        for lineno, entry in files:
            norm = entry.replace("\\", "/").lstrip("./")
            low = norm.lower()
            if low in seen:
                result["duplicate_entries"].append(norm)
            seen[low] = True
            if low in real:
                actual = real[low]
                if actual != norm:
                    result["case_mismatch"].append("%s → %s" % (norm, actual))
            else:
                result["missing_files"].append(norm)

    # ---- обход дерева ----
    for root, dirs, files in os.walk(addon_dir):
        rel_root = os.path.relpath(root, addon_dir)

        for d in list(dirs):
            if d in JUNK_NAMES:
                p = os.path.join(root, d)
                result["junk"].append(os.path.relpath(p, addon_dir) + "/")
                dirs.remove(d)

        if not dirs and not files and rel_root != ".":
            result["empty_dirs"].append(rel_root)

        for f in files:
            rel = os.path.relpath(os.path.join(root, f), addon_dir)
            low = f.lower()

            if f in JUNK_NAMES or low.endswith(JUNK_SUFFIXES):
                result["junk"].append(rel)

            if low.endswith(".lua"):
                result["lua_files"] += 1
                enc = detect_encoding(os.path.join(root, f))
                result["encodings"][enc] = result["encodings"].get(enc, 0) + 1
                if any(marker in rel.lower() for marker in LOCALE_MARKERS):
                    result["has_ru"] = True
                    result["ru_files"].append(rel)
                elif has_cyrillic(os.path.join(root, f)):
                    # русские строки прямо в коде (без файла локализации)
                    result["ru_text_files"].append(rel)
            elif low.endswith(".xml"):
                result["xml_files"] += 1
                if has_cyrillic(os.path.join(root, f)):
                    result["ru_text_files"].append(rel)
                try:
                    ET.parse(os.path.join(root, f))
                except ET.ParseError as exc:
                    result["xml_errors"].append("%s: %s" % (rel, exc))

    return result


def run_lua_syntax(addons_root, dirs):
    """Проверка синтаксиса Lua через Fengari (node)."""
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "lua_syntax.js")
    if not os.path.exists(script):
        return None
    try:
        proc = subprocess.run(["node", script, addons_root] + dirs,
                              capture_output=True, text=True, timeout=600)
        if proc.returncode != 0 and not proc.stdout.strip():
            return {"error": proc.stderr.strip()[-400:]}
        return json.loads(proc.stdout)
    except Exception as exc:  # noqa: BLE001
        return {"error": str(exc)}


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1

    root = sys.argv[1].rstrip("/")
    json_out = None
    if "--json" in sys.argv:
        json_out = sys.argv[sys.argv.index("--json") + 1]

    addons = sorted(d for d in os.listdir(root)
                    if os.path.isdir(os.path.join(root, d)))
    results = [check_addon(os.path.join(root, d)) for d in addons]

    syntax = run_lua_syntax(root, addons)
    if syntax and "error" not in syntax:
        for res in results:
            res["lua_errors"] = syntax.get(res["name"], [])
    elif syntax and "error" in syntax:
        print("! Проверка синтаксиса Lua недоступна: " + syntax["error"])

    # ---- отчёт ----
    total_errors = 0
    total_warnings = 0
    print("=" * 78)
    print("АУДИТ АДДОНОВ: %s" % root)
    print("=" * 78)

    by_name = {res["name"]: res for res in results}

    def ru_covered(res):
        """Русский есть: файл локализации, кириллица в коде или родительский аддон."""
        if res["has_ru"] or res["ru_text_files"]:
            return True
        base = res["name"].split("_")[0]
        return base != res["name"] and base in by_name and (
            by_name[base]["has_ru"] or by_name[base]["ru_text_files"])

    for res in results:
        errs, warns = [], []

        for m in res["missing_files"]:
            errs.append("в .toc указан отсутствующий файл: " + m)
        for e in res["lua_errors"]:
            # "(5.1-ok)" — расхождения Lua 5.1 и 5.3, для клиента 3.3.5 не ошибка
            if "(5.1-ok)" in e:
                warns.append("Lua: " + e.replace("(5.1-ok) ", ""))
            else:
                errs.append("Lua: " + e)
        for e in res["xml_errors"]:
            errs.append("XML: " + e)
        if res["toc"] is None and res["notes"]:
            errs.append(res["notes"][0])

        for c in res["duplicate_entries"]:
            warns.append("файл указан в .toc дважды: " + c)
        for c in res["case_mismatch"]:
            warns.append("регистр имени в .toc: " + c)
        for j in res["junk"]:
            warns.append("мусор: " + j)
        for e in res["empty_dirs"][:3]:
            warns.append("пустой каталог: " + e)
        if res["interface"] and res["interface"] not in ("30300", "30300 "):
            warns.append("## Interface: %s (для 3.3.5 ожидается 30300)" % res["interface"])
        if not ru_covered(res) and res["lua_files"] > 0:
            warns.append("нет русского текста (ни ruRU-файла, ни кириллицы)")

        total_errors += len(errs)
        total_warnings += len(warns)

        status = "OK" if not errs else "ОШИБКИ(%d)" % len(errs)
        print("\n%-30s %-12s файлов:%-4d lua:%-4d  %s"
              % (res["name"][:29], status, res["files_listed"], res["lua_files"],
                 res["title"] or ""))
        if res["encodings"]:
            print("    кодировки: %s" % ", ".join("%s=%d" % kv for kv in res["encodings"].items()))
        for e in errs:
            print("    ✗ " + e)
        for w in warns:
            print("    · " + w)

    print("\n" + "=" * 78)
    print("Итого: аддонов %d, ошибок %d, замечаний %d"
          % (len(results), total_errors, total_warnings))
    print("=" * 78)

    if json_out:
        with open(json_out, "w", encoding="utf-8") as fh:
            json.dump(results, fh, ensure_ascii=False, indent=1)
        print("Отчёт: %s" % json_out)

    return 1 if total_errors else 0


if __name__ == "__main__":
    sys.exit(main())
