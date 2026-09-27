#!/usr/bin/env python3
"""Перевод Lua-скриптов Eluna: копирует server-files/lua_scripts в server-files-ru/lua_scripts
и заменяет строковые литералы по словарям lua_dict_*.py (ключ = точное содержимое литерала).
Меняются только литералы в кавычках, код и комментарии не трогаются."""
import os, re, shutil, glob, importlib.util, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "server-files", "lua_scripts")
DST = os.path.join(ROOT, "server-files-ru", "lua_scripts")
HERE = os.path.dirname(os.path.abspath(__file__))

D = {}          # {файл(относит.) или '*': {orig: ru}}
for p in sorted(glob.glob(os.path.join(HERE, "lua_dict_*.py"))):
    spec = importlib.util.spec_from_file_location(os.path.basename(p)[:-3], p)
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
    for f, d in m.D.items():
        D.setdefault(f, {}).update(d)

LIT = re.compile(r'--\[(=*)\[.*?\]\1\]|--[^\n]*|"((?:[^"\\\n]|\\.)*)"|\'((?:[^\'\\\n]|\\.)*)\'', re.S)
FMT = re.compile(r'%[-+ #0]*\d*(?:\.\d+)?[sdifxXcuq%]')

ALLOW_DROP = {"Set links are locked for %d more minute%s."}

def esc(s, q):
    return s.replace("\\", "\\\\").replace(q, "\\" + q).replace("\n", "\\n")

def process(rel, text, dic, used, bad):
    def rep(m):
        if m.group(0).startswith("--"):
            return m.group(0)
        q = '"' if m.group(2) is not None else "'"
        raw = m.group(2) if q == '"' else m.group(3)
        if raw in dic:
            ru = dic[raw]; used.add(raw)
            a, b = FMT.findall(raw), FMT.findall(ru)
            # допускается отбросить хвостовые плейсхолдеры (лишние аргументы string.format игнорирует)
            if not (a == b or (sorted(a) == sorted(b)) or (raw in ALLOW_DROP and a[:len(b)] == b)):
                bad.append((rel, raw, ru))
            # ru задаётся уже в виде Lua-содержимого (с теми же escape), экранируем только кавычку
            return q + ru.replace(q, "\\" + q) + q
        return m.group(0)
    return LIT.sub(rep, text)

def main():
    if os.path.exists(DST): shutil.rmtree(DST)
    shutil.copytree(SRC, DST)
    total = 0; bad = []; unused = []
    for path in sorted(glob.glob(os.path.join(DST, "**", "*.lua"), recursive=True)):
        rel = os.path.relpath(path, DST).replace(os.sep, "/")
        dic = dict(D.get("*", {})); dic.update(D.get(rel, {}))
        if rel not in D: continue
        raw = open(path, "rb").read()
        text = raw.decode("utf-8")
        used = set()
        new = process(rel, text, dic, used, bad)
        open(path, "wb").write(new.encode("utf-8"))
        n = len(used); total += n
        miss = [k for k in D.get(rel, {}) if k not in used]
        unused += [(rel, k) for k in miss]
        print(f"  {rel}: переведено строк {n}")
    print("Всего:", total)
    for r, k in unused: print("  !! не найдено в", r, ":", k[:80])
    for r, a, b in bad: print("  !! плейсхолдеры", r, ":", a[:60], "=>", b[:60])
    if bad: sys.exit(1)
main()
