#!/usr/bin/env bash
#===========================================================================
# tools/build.sh — сборка аддона для установки в World of Warcraft 3.3.5
#
# Делает:
#   1. проверяет, что все файлы из .toc на месте
#   2. проверяет, что Bindings.xml — корректный XML
#   3. собирает dist/AdminToolsRU/ и dist/AdminToolsRU.zip
#
# Запуск:  ./tools/build.sh        (из корня репозитория)
#          bash tools/build.sh
#===========================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/AdminToolsRU"
DIST="$ROOT/dist"
ADDON="$DIST/AdminToolsRU"
TOC="$SRC/AdminToolsRU.toc"

green() { printf '\033[32m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }
dim()   { printf '\033[2m%s\033[0m\n' "$1"; }

[ -f "$TOC" ] || { red "Не найден $TOC"; exit 1; }

#--------------------------------------------------------------- 1. файлы
echo "Проверяю файлы из .toc…"
missing=0
while IFS= read -r line; do
	line="${line%$'\r'}"
	[[ -z "${line// }" || "$line" == \#* ]] && continue
	file="${line%%[[:space:]]*}"
	if [ ! -f "$SRC/$file" ]; then
		red "  отсутствует: $file"
		missing=1
	else
		dim "  ок: $file"
	fi
done < "$TOC"
[ "$missing" -eq 0 ] || { red "Сборка прервана: в .toc указаны несуществующие файлы."; exit 1; }

#--------------------------------------------------------- 2. Bindings.xml
if [ -f "$SRC/Bindings.xml" ]; then
	echo "Проверяю Bindings.xml…"
	if python3 -c "import xml.dom.minidom,sys; xml.dom.minidom.parse('$SRC/Bindings.xml')" 2>/dev/null; then
		dim "  XML корректен"
	else
		red "  Bindings.xml не является корректным XML"
		exit 1
	fi
fi

#--------------------------------------------------------------- 3. сборка
echo "Собираю пакет…"
rm -rf "$DIST"
mkdir -p "$ADDON"
cp "$SRC"/*.lua "$SRC"/*.toc "$ADDON/"
[ -f "$SRC/Bindings.xml" ] && cp "$SRC/Bindings.xml" "$ADDON/"

# текстуры оформления — без них кнопки останутся без скина
if [ -d "$SRC/skin" ]; then
	mkdir -p "$ADDON/skin"
	cp "$SRC"/skin/*.tga "$ADDON/skin/"
	dim "  скин: $(ls -1 "$SRC"/skin/*.tga | wc -l) текстур"
else
	red "  нет папки skin/ — запусти python3 tools/gen_textures.py"
	exit 1
fi

# убрать служебное, если попадёт
rm -f "$ADDON"/*.bak "$ADDON"/*.orig 2>/dev/null || true

( cd "$DIST" && zip -qr "AdminToolsRU.zip" "AdminToolsRU" )

green ""
green "Готово!"
echo "  папка:  dist/AdminToolsRU/"
echo "  архив:  dist/AdminToolsRU.zip"
echo "  размер: $(du -h "$DIST/AdminToolsRU.zip" | cut -f1)"
echo "  sha256: $(sha256sum "$DIST/AdminToolsRU.zip" | cut -d' ' -f1)"
echo ""
echo "Установка:"
echo "  1) распаковать AdminToolsRU.zip (или скопировать папку AdminToolsRU)"
echo "     в  <WoW>/Interface/AddOns/"
echo "  2) перезапустить игру или нажать «Перезагрузить интерфейс»"
echo "  3) в списке аддонов включить «Admin Tools RU»"
