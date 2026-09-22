#!/usr/bin/env python3
#===========================================================================
# tools/mockup.py — макет панели Admin Tools RU для просмотра без игры.
#
# Рисует окно теми же текстурами (AdminToolsRU/skin/*.tga) и с теми же
# координатами, что в Core.lua: размер, колонка вкладок, шаг кнопок,
# цвета уровней доступа. Это превью дизайна, а не скриншот клиента.
#
# Запуск:  python3 tools/mockup.py
# Результат: tools/preview/panel-mockup.png
#===========================================================================

import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIN = os.path.join(ROOT, "AdminToolsRU", "skin")
OUT = os.path.join(ROOT, "tools", "preview", "panel-mockup.png")

# ---- геометрия и цвета: 1:1 с Core.lua --------------------------------
W, H = 880, 620
BTN_W, BTN_H, PAD = 142, 22, 6
TAB_W, TAB_H, TAB_STEP = 132, 24, 26
PAGE_L, PAGE_TOP, PAGE_BOTTOM, PAGE_R = 160, 118, 60, 16
COLS = 4

BG        = (11, 14, 19)
BORDER    = (41, 46, 61)
ACCENT    = (46, 214, 255)
TEXT      = (230, 235, 245)
TEXT_DIM  = (140, 148, 168)
SEC_RGB   = {1: (77, 255, 102), 2: (255, 230, 64), 3: (255, 89, 89)}

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def font(size, bold=False):
    return ImageFont.truetype(FONT_B if bold else FONT, size)


def tint(img, color, alpha=1.0):
    """Окрасить текстуру скина в цвет (как SetVertexColor в игре)."""
    img = img.convert("RGBA")
    px = img.load()
    r, g, b, a = color[0] / 255.0, color[1] / 255.0, color[2] / 255.0, alpha
    for y in range(img.height):
        for x in range(img.width):
            pr, pg, pb, pa = px[x, y]
            px[x, y] = (int(pr * r), int(pg * g), int(pb * b), int(pa * a))
    return img


def load(name):
    return Image.open(os.path.join(SKIN, name + ".tga"))


def stretch(img, w, h):
    return img.resize((max(1, int(w)), max(1, int(h))), Image.BILINEAR)


# ---- холст -------------------------------------------------------------
canvas = Image.new("RGBA", (W, H), BG + (255,))
draw = ImageDraw.Draw(canvas)

# свечение в шапке
glow = tint(stretch(load("glow"), W, 150), ACCENT, 0.13)
canvas.alpha_composite(glow, (0, 0))

# рамка окна
draw.rectangle([0, 0, W - 1, H - 1], outline=BORDER, width=1)

# ---- шапка -------------------------------------------------------------
draw.text((18, 10), "Admin Tools RU", font=font(19, True), fill=(255, 255, 255))
bbox = draw.textbbox((18, 10), "Admin Tools RU", font=font(19, True))
draw.text((bbox[2] + 8, bbox[3] - 13), "v5.1.0", font=font(11), fill=TEXT_DIM)
draw.text((18, 34), "AzerothCore · NPCBots + Extras · Custom Races",
          font=font(11), fill=TEXT_DIM)
draw.text((W - 30, 12), "✕", font=font(16), fill=TEXT_DIM)

# ---- строка избранного -------------------------------------------------
draw.text((18, 50), "Избранное:", font=font(11), fill=TEXT)
favs = ["Банк", "Починить всё", "Порталы", "Трансмог"]
fx = 88
for name in favs:
    img = tint(stretch(load("btn-normal"), 104, 18), (255, 255, 255), 0.9)
    canvas.alpha_composite(img, (fx, 48))
    draw.text((fx + 52, 51), name, font=font(10), fill=TEXT, anchor="ma")
    fx += 110

# разделитель под шапкой
line = tint(stretch(load("line"), W - 28, 8), ACCENT, 0.45)
canvas.alpha_composite(line, (14, 79))

# ---- колонка вкладок ---------------------------------------------------
TABS = ["Мир", "Телепорт", "Путешествие", "Боты", "NPC", "Модули",
        "Себя", "Персонаж", "Группа", "Сервер", "Настройки", "Свои"]
ACTIVE = "Боты"

tab_bg = tint(stretch(load("panel"), TAB_W + 14, H - 84 - PAGE_BOTTOM), (13, 15, 23), 0.55)
canvas.alpha_composite(tab_bg, (8, 84))

for i, name in enumerate(TABS):
    y = 90 + i * TAB_STEP
    active = (name == ACTIVE)
    if active:
        bg = tint(stretch(load("btn-hover"), TAB_W, TAB_H), ACCENT, 0.55)
        canvas.alpha_composite(bg, (14, y))
        marker = tint(stretch(load("line"), 4, TAB_H), ACCENT, 1.0)
        canvas.alpha_composite(marker, (14, y))
        color = (255, 255, 255)
    else:
        bg = tint(stretch(load("btn-normal"), TAB_W, TAB_H), (255, 255, 255), 1.0)
        canvas.alpha_composite(bg, (14, y))
        color = TEXT_DIM
    draw.text((26, y + TAB_H // 2), name, font=font(12), fill=color, anchor="lm")

# ---- заголовок вкладки + фильтр ---------------------------------------
draw.text((PAGE_L, PAGE_TOP - 26), ACTIVE, font=font(14, True), fill=(255, 255, 255))
draw.rectangle([W - 250, PAGE_TOP - 18, W - 30, PAGE_TOP + 2], outline=(70, 76, 96), width=1)
draw.text((W - 244, PAGE_TOP - 13), "фильтр…", font=font(11), fill=TEXT_DIM)

# ---- содержимое вкладки «Боты» ----------------------------------------
y = PAGE_TOP

def section(title):
    global y
    draw.text((PAGE_L + 6, y), title, font=font(13, True), fill=(255, 255, 255))
    ln = tint(stretch(load("line"), W - PAGE_L - PAGE_R - 16, 8), ACCENT, 0.40)
    canvas.alpha_composite(ln, (PAGE_L + 5, y + 17))
    y += 20


def buttons(items, cols=COLS):
    """items: список (подпись, уровень доступа)"""
    global y
    for i, (label, sec) in enumerate(items):
        col, row = i % cols, i // cols
        x = PAGE_L + 4 + col * (BTN_W + PAD)
        by = y + row * (BTN_H + PAD)
        base = load("btn-normal")
        canvas.alpha_composite(tint(stretch(base, BTN_W, BTN_H), (255, 255, 255), 1.0), (x, by))
        draw.text((x + BTN_W // 2, by + BTN_H // 2),
                  label, font=font(10), fill=SEC_RGB.get(sec, TEXT), anchor="mm")
    rows = (len(items) + cols - 1) // cols
    y += rows * (BTN_H + PAD) + PAD


def form(label, value=""):
    global y
    draw.text((PAGE_L + 6, y + 5), label, font=font(10), fill=TEXT)
    draw.rectangle([PAGE_L + 190, y, PAGE_L + 430, y + 20], outline=(70, 76, 96))
    if value:
        draw.text((PAGE_L + 196, y + 4), value, font=font(10), fill=TEXT)
    img = tint(stretch(load("btn-normal"), 40, 20), (255, 255, 255), 1.0)
    canvas.alpha_composite(img, (PAGE_L + 436, y))
    draw.text((PAGE_L + 456, y + 10), "OK", font=font(9), fill=TEXT, anchor="mm")
    y += 26


section("Отряд: движение и поведение")
buttons([
    ("Следовать", 1), ("Только следовать", 1), ("Стоять", 1), ("Полный стоп", 1),
    ("Шаг", 1), ("Без сплетен", 1), ("Воскресить", 1), ("Спрятать", 1),
])
section("Дистанция следования")
buttons([("10 ярдов", 1), ("30 ярдов", 1), ("50 ярдов", 1),
         ("75 ярдов", 1), ("Атака: близко", 1), ("Атака: далеко", 1)])
section("Найм, поиск, спавн")
form("Найти по классу (номер):", "3")
form("Заспавнить бота (ID):")
section("Настройка выделенного бота (GM)")
buttons([("Присвоить себе", 3), ("Уволить", 3), ("Освободить", 3)])

# ---- нижняя панель -----------------------------------------------------
draw.text((20, H - 34), "Команда:", font=font(11), fill=TEXT)
draw.rectangle([92, H - 36, 522, H - 16], outline=(70, 76, 96))
img = tint(stretch(load("btn-normal"), 90, 20), (255, 255, 255), 1.0)
canvas.alpha_composite(img, (530, H - 36))
draw.text((575, H - 26), "Выполнить", font=font(9), fill=TEXT, anchor="mm")
for i, ch in enumerate("▲▼"):
    canvas.alpha_composite(tint(stretch(load("btn-normal"), 26, 20), (255, 255, 255), 1.0),
                           (628 + i * 30, H - 36))
    draw.text((641 + i * 30, H - 26), ch, font=font(9), fill=TEXT, anchor="mm")
draw.text((694, H - 26), "история: 5", font=font(10), fill=TEXT_DIM, anchor="lm")

draw.text((20, H - 12), "ЛКМ — выполнить · ПКМ — команда в поле ввода · Shift+ЛКМ — в избранное",
          font=font(10), fill=(95, 102, 122))

os.makedirs(os.path.dirname(OUT), exist_ok=True)
canvas.convert("RGB").save(OUT)
print("Макет панели:", os.path.relpath(OUT, ROOT))
