#!/usr/bin/env python3
#===========================================================================
# tools/mockup.py — макеты панели Admin Tools RU (просмотр без игры).
#
# Рисует окно теми же текстурами (AdminToolsRU/skin/*.tga), геометрией и
# цветами, что в Core.lua / Tab_Interface.lua.
#
# Запуск:  python3 tools/mockup.py
# Результат:
#   tools/preview/panel-mockup.png     вкладка «Боты»
#   tools/preview/panel-interface.png  вкладка «Интерфейс»
#   tools/preview/themes-preview.png   все пять тем рядом
#===========================================================================

import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIN = os.path.join(ROOT, "AdminToolsRU", "skin")
OUT = os.path.join(ROOT, "tools", "preview")

# ---- геометрия 1:1 с Core.lua ------------------------------------------
W, H = 880, 620
BTN_W, BTN_H, PAD = 142, 22, 6
TAB_W, TAB_H, TAB_STEP = 132, 24, 26
PAGE_L, PAGE_TOP, PAGE_BOTTOM, PAGE_R = 160, 118, 60, 16
COLS = 4

# ---- темы 1:1 с AT.Themes в Core.lua ----------------------------------
THEMES = {
    "cyan":    dict(name="Голубая",     bg=(11, 14, 19),  border=(41, 46, 61),
                    accent=(46, 214, 255), text=(230, 235, 245), dim=(140, 148, 168)),
    "emerald": dict(name="Изумрудная",  bg=(10, 18, 15),  border=(41, 66, 56),
                    accent=(77, 242, 158), text=(226, 242, 234), dim=(139, 168, 155)),
    "violet":  dict(name="Аметистовая", bg=(15, 11, 23),  border=(61, 46, 82),
                    accent=(179, 115, 255), text=(235, 229, 245), dim=(162, 150, 186)),
    "amber":   dict(name="Янтарная",    bg=(19, 15, 9),   border=(71, 56, 36),
                    accent=(255, 184, 64), text=(245, 238, 226), dim=(186, 168, 139)),
    "rose":    dict(name="Розовая",     bg=(20, 11, 15),  border=(77, 46, 61),
                    accent=(255, 115, 166), text=(245, 230, 235), dim=(186, 150, 162)),
}

SEC_RGB = {1: (77, 255, 102), 2: (255, 230, 64), 3: (255, 89, 89)}

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

_cache = {}


def font(size, bold=False):
    key = (size, bold)
    if key not in _cache:
        _cache[key] = ImageFont.truetype(FONT_B if bold else FONT, size)
    return _cache[key]


def load(name):
    key = ("tex", name)
    if key not in _cache:
        _cache[key] = Image.open(os.path.join(SKIN, name + ".tga")).convert("RGBA")
    return _cache[key]


def tint(img, color, alpha=1.0):
    key = ("tint", id(img), color, round(alpha, 3))
    if key in _cache:
        return _cache[key]
    out = img.copy()
    px = out.load()
    r, g, b = color[0] / 255.0, color[1] / 255.0, color[2] / 255.0
    for y in range(out.height):
        for x in range(out.width):
            pr, pg, pb, pa = px[x, y]
            px[x, y] = (int(pr * r), int(pg * g), int(pb * b), int(pa * alpha))
    _cache[key] = out
    return out


def stretch(img, w, h):
    return img.resize((max(1, int(w)), max(1, int(h))), Image.BILINEAR)


def comp(canvas, img, xy, color, alpha=1.0):
    canvas.alpha_composite(tint(stretch(img, img.width, img.height), color, alpha), xy)


class Panel:
    """Рисует окно панели: шапка, избранное, колонка вкладок, содержимое."""

    def __init__(self, theme_key, tabs, active, w=W, h=H, scale=1.0):
        self.t = THEMES[theme_key]
        self.w, self.h, self.scale = w, h, scale
        self.s = scale
        self.canvas = Image.new("RGBA", (int(w * scale), int(h * scale)), self.t["bg"] + (255,))
        self.d = ImageDraw.Draw(self.canvas)
        self.tabs = tabs
        self.active = active
        self.fs = lambda size, bold=False: font(max(6, int(size * scale)), bold)

    def px(self, v):
        return v * self.s

    def full(self, img, x, y, w, h, color, alpha=1.0):
        """Наложить текстуру скина, растянутую в矩形 w×h."""
        self.canvas.alpha_composite(tint(stretch(img, self.px(w), self.px(h)), color, alpha),
                                    (int(self.px(x)), int(self.px(y))))

    def text(self, x, y, s, size=10, color=None, bold=False, anchor="la"):
        self.d.text((self.px(x), self.px(y)), s, font=self.fs(size, bold),
                    fill=color or self.t["text"], anchor=anchor)

    # ---------------------------------------------------------------- шапка
    def header(self, title="Admin Tools RU", version="v5.2.0"):
        a = self.t["accent"]
        self.full(load("glow"), 0, 0, self.w, 150, a, 0.13)
        self.d.rectangle([0, 0, int(self.px(self.w)) - 1, int(self.px(self.h)) - 1],
                         outline=self.t["border"], width=1)
        self.text(18, 10, title, 19, (255, 255, 255), bold=True)
        # версия — рядом с заголовком (учитываем ширину текста)
        tw = self.d.textlength(title, font=self.fs(19, True))
        self.text(18 + (tw + 8) / self.s, 21, version, 11, self.t["dim"])
        self.text(18, 34, "AzerothCore - NPCBots + Extras - Custom Races", 11, self.t["dim"])

        # строка избранного
        self.text(18, 50, "Избранное:", 11)
        fx = 88
        for name in ("Банк", "Починить всё", "Порталы", "Трансмог"):
            self.full(load("btn-normal"), fx, 48, 104, 18, (255, 255, 255), 1.0)
            self.text(fx + 52, 51, name, 10, anchor="ma")
            fx += 110

        self.full(load("line"), 14, 79, self.w - 28, 8, a, 0.45)

    # ------------------------------------------------------------ вкладки
    def tab_column(self):
        self.full(load("panel"), 8, 84, TAB_W + 14, self.h - 84 - PAGE_BOTTOM, (13, 15, 23), 0.55)
        for i, name in enumerate(self.tabs):
            y = 90 + i * TAB_STEP
            active = (name == self.active)
            if active:
                self.full(load("btn-hover"), 14, y, TAB_W, TAB_H, self.t["accent"], 0.55)
                self.full(load("line"), 14, y, 4, TAB_H, self.t["accent"], 1.0)
                color = (255, 255, 255)
            else:
                self.full(load("btn-normal"), 14, y, TAB_W, TAB_H, (255, 255, 255), 1.0)
                color = self.t["dim"]
            self.text(26, y + TAB_H / 2 - 5, name, 12, color)

    # ------------------------------------------------------- содержимое
    def section(self, y, title):
        self.d.text((self.px(PAGE_L + 6), self.px(y)), title, font=self.fs(13, True),
                    fill=(255, 255, 255))
        self.full(load("line"), PAGE_L + 5, y + 17, self.w - PAGE_L - PAGE_R - 16, 8,
                  self.t["accent"], 0.40)
        return y + 20

    def buttons(self, y, items, cols=COLS, hover_row=None):
        cell = max((i[2] if len(i) > 2 else BTN_W) for i in items)
        for i, item in enumerate(items):
            label, sec = item[0], item[1]
            col, row = i % cols, i // cols
            x = PAGE_L + 4 + col * (cell + PAD)
            by = y + row * (BTN_H + PAD)
            if hover_row is not None and row == hover_row:
                self.full(load("panel"), x - 2, by - 2, cell + 4, BTN_H + 4,
                          self.t["accent"], 0.10)
            self.full(load("btn-normal"), x, by, cell, BTN_H, (255, 255, 255), 1.0)
            self.text(x + cell / 2, by + 6, label, 10, SEC_RGB.get(sec, self.t["text"]), anchor="ma")
        rows = (len(items) + cols - 1) // cols
        return y + rows * (BTN_H + PAD) + PAD

    def checkbox(self, y, label, checked=True):
        x, size = PAGE_L + 4, 14
        self.d.rectangle([self.px(x), self.px(y + 4), self.px(x + size), self.px(y + 4 + size)],
                         outline=self.t["dim"], width=1)
        if checked:
            self.full(load("panel"), x + 3, y + 7, size - 6, size - 6, self.t["accent"], 1.0)
        self.text(x + size + 6, y + 5, label, 10)
        return y + 26

    def filter_box(self, hint="фильтр…"):
        self.d.rectangle([self.px(self.w - 250), self.px(PAGE_TOP - 18),
                          self.px(self.w - 30), self.px(PAGE_TOP + 2)],
                         outline=(70, 76, 96), width=1)
        self.text(self.w - 244, PAGE_TOP - 13, hint, 11, self.t["dim"])
        self.text(PAGE_L, PAGE_TOP - 26, self.active, 14, (255, 255, 255), bold=True)

    def footer(self, quick="ЛКМ — выполнить. ПКМ — команда в поле ввода. Shift+ЛКМ — в избранное."):
        self.text(20, self.h - 34, "Команда:", 11)
        self.d.rectangle([self.px(92), self.px(self.h - 36), self.px(522), self.px(self.h - 16)],
                         outline=(70, 76, 96), width=1)
        self.full(load("btn-normal"), 530, self.h - 36, 90, 20, (255, 255, 255), 1.0)
        self.text(575, self.h - 26, "Выполнить", 9, anchor="mm")
        for i, ch in enumerate(("Вверх", "Вниз")):
            x = 628 + i * 62
            self.full(load("btn-normal"), x, self.h - 36, 58, 20, (255, 255, 255), 1.0)
            self.text(x + 29, self.h - 26, ch, 9, anchor="mm")
        self.text(760, self.h - 26, "история: 5", 10, self.t["dim"], anchor="lm")
        self.text(20, self.h - 12, quick, 10, (95, 102, 122))

    def save(self, path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        self.canvas.convert("RGB").save(path)
        print("  ", os.path.relpath(path, ROOT))


TABS = ["Мир", "Телепорт", "Путешествие", "Боты", "NPC", "Модули",
        "Себя", "Персонаж", "Группа", "Сервер", "Интерфейс", "Настройки", "Свои"]


#===========================================================================
# 1) Вкладка «Боты» (голубая тема)
#===========================================================================
def draw_bots():
    p = Panel("cyan", TABS, "Боты")
    p.header()
    p.tab_column()
    p.filter_box()

    y = PAGE_TOP
    y = p.section(y, "Отряд: движение и поведение")
    y = p.buttons(y, [
        ("Следовать", 1), ("Только следовать", 1), ("Стоять", 1), ("Полный стоп", 1),
        ("Шаг", 1), ("Без сплетен", 1), ("Воскресить", 1), ("Спрятать", 1),
    ], hover_row=1)

    y = p.section(y, "Дистанция следования")
    y = p.buttons(y, [("10 ярдов", 1), ("30 ярдов", 1), ("50 ярдов", 1),
                      ("75 ярдов", 1), ("Атака: близко", 1), ("Атака: далеко", 1)])

    y = p.section(y, "Настройка выделенного бота (GM)")
    y = p.buttons(y, [("Присвоить себе", 3), ("Уволить", 3), ("Освободить", 3)])
    p.footer()
    p.save(os.path.join(OUT, "panel-mockup.png"))


#===========================================================================
# 2) Вкладка «Интерфейс»
#===========================================================================
def draw_interface(theme_key="cyan", path="panel-interface.png"):
    p = Panel(theme_key, TABS, "Интерфейс")
    p.header()
    p.tab_column()
    p.filter_box()

    y = PAGE_TOP
    y = p.section(y, "Тема оформления")

    # 5 кнопок-образцов тем, у каждой цветной точкой
    for i, key in enumerate(THEMES):
        th = THEMES[key]
        x = PAGE_L + 4 + i * 136
        p.full(load("btn-normal"), x, y, 130, BTN_H, (255, 255, 255), 1.0)
        p.full(load("panel"), x + 6, y + 6, 10, 10, th["accent"], 0.85)
        active = (key == theme_key)
        p.text(x + 22, y + 6, th["name"], 10,
               (255, 255, 255) if active else p.t["text"])
    y = y + 26
    p.text(PAGE_L + 6, y, "Сейчас: %s. Тема сохраняется и меняет вид всей панели."
           % THEMES[theme_key]["name"], 10, p.t["dim"])
    y += 20

    y = p.section(y, "Размер окна")
    y = p.buttons(y, [("Компактный", None), ("Обычный", None), ("Широкий", None),
                      ("Максимум", None)], hover_row=0)

    y = p.section(y, "Положение окна")
    y = p.buttons(y, [("По центру", None), ("Слева", None), ("Справа", None),
                      ("Сверху", None)])

    y = p.section(y, "Кнопка на миникарте")
    p.full(load("btn-normal"), PAGE_L + 4, y, 200, BTN_H, (255, 255, 255), 1.0)
    p.text(PAGE_L + 104, y + 6, "Скрыть кнопку миникарты", 10, anchor="ma")
    p.text(PAGE_L + 216, y + 6, "угол 90 градусов", 10)
    y += 26
    p.text(PAGE_L + 6, y, "Угол на окружности миникарты:", 10)
    y += 18
    angles = [("180", None), ("135", None), ("90", None), ("45", None),
              ("0", None), ("315", None), ("270", None), ("225", None)]
    for i, (label, _) in enumerate(angles):
        col, row = i % 4, i // 4
        x = PAGE_L + 4 + col * (56 + PAD) + col * 0
        x = PAGE_L + 4 + col * 62
        by = y + row * (BTN_H + PAD)
        p.full(load("btn-normal"), x, by, 56, BTN_H, (255, 255, 255), 1.0)
        p.text(x + 28, by + 6, label, 10, anchor="ma")
    x = PAGE_L + 4 + 4 * 62 + 10
    p.full(load("btn-normal"), x, y, 130, BTN_H, (255, 255, 255), 1.0)
    p.text(x + 65, y + 6, "По умолчанию", 10, anchor="ma")
    y += 2 * (BTN_H + PAD) + PAD

    y = p.section(y, "Чтение интерфейса")
    y = p.checkbox(y, "Подсветка строк при наведении", True)
    y = p.checkbox(y, "Всплывающие подсказки", True)
    y = p.checkbox(y, "Поля фильтра на вкладках", True)
    y = p.checkbox(y, "Кнопка панели на миникарте", True)

    p.footer()
    p.save(os.path.join(OUT, path))


#===========================================================================
# 3) Все темы рядом
#===========================================================================
def draw_tile_content(p):
    """Компактное содержимое для превью темы: шапка, вкладки, кнопки, футер."""
    p.header()
    p.tab_column()
    p.filter_box()

    y = PAGE_TOP
    y = p.section(y, "Отряд: движение и поведение")
    y = p.buttons(y, [
        ("Следовать", 1), ("Только следовать", 1), ("Стоять", 1), ("Полный стоп", 1),
        ("Шаг", 1), ("Без сплетен", 1), ("Воскресить", 1), ("Спрятать", 1),
    ], hover_row=1)
    y = p.section(y, "Дистанция следования")
    y = p.buttons(y, [("10 ярдов", 1), ("30 ярдов", 1), ("50 ярдов", 1), ("75 ярдов", 1)])
    y = p.section(y, "Настройка выделенного бота (GM)")
    y = p.buttons(y, [("Присвоить себе", 3), ("Уволить", 3), ("Освободить", 3)])
    p.footer()
    return p


def draw_themes():
    scale = 0.62
    tiles = []
    for key in THEMES:
        p = Panel(key, TABS, "Боты", scale=scale)
        draw_tile_content(p)
        tiles.append(p)
    tw, th = tiles[0].canvas.width, tiles[0].canvas.height
    gap = 14
    canvas = Image.new("RGBA", (tw * 2 + gap * 3, (th + gap + 26) * 3), (14, 16, 22, 255))
    d = ImageDraw.Draw(canvas)

    for i, (key, tile) in enumerate(zip(THEMES, tiles)):
        col, row = i % 2, i // 2
        x = gap + col * (tw + gap)
        y = gap + row * (th + gap + 26)
        canvas.alpha_composite(tile.canvas, (x, y))
        d.text((x, y + th + 6), "Тема: %s" % THEMES[key]["name"],
               font=font(15, True), fill=THEMES[key]["accent"])

    path = os.path.join(OUT, "themes-preview.png")
    canvas.convert("RGB").save(path)
    print("  ", os.path.relpath(path, ROOT))


def main():
    print("Макеты панели:")
    draw_bots()
    draw_interface()
    draw_interface("emerald", "panel-interface-emerald.png")
    draw_themes()


if __name__ == "__main__":
    main()
