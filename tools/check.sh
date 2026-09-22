#!/usr/bin/env bash
#===========================================================================
# tools/check.sh — быстрая проверка аддона перед установкой в игру.
#
# Запускает полный набор автотестов: аддон загружается в настоящий
# Lua-интерпретатор на заглушке WoW API, кликаются все кнопки, проверяются
# команды, попапы, меню, вкладки и настройки.
#
# Первый запуск:  cd tools && npm install
# Проверка:       ./tools/check.sh
#===========================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
green() { printf '\033[32m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }

if ! command -v node >/dev/null 2>&1; then
	red "Не найден node.js — без него автотесты не запустить."
	echo "Установи Node.js 16+ (https://nodejs.org) и повтори."
	exit 1
fi

if [ ! -d "$ROOT/tools/node_modules/fengari" ]; then
	echo "Ставлю зависимости (нужен интернет, только в первый раз)…"
	( cd "$ROOT/tools" && npm install --no-audit --no-fund )
fi

cd "$ROOT/tools"
npm test
green ""
green "Проверка завершена успешно — аддон готов к установке."
echo "Собрать архив: ./tools/build.sh"
