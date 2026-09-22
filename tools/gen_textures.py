#!/usr/bin/env python3
#===========================================================================
# tools/gen_textures.py — генератор текстур скина аддона.
#
# WoW 3.3.5 читает TGA (32 бита, без сжатия), поэтому текстуры пишутся
# вручную — никаких внешних библиотек не нужно.
#
# Запуск:  python3 tools/gen_textures.py
#
# Результат:
#   AdminToolsRU/skin/*.tga   — текстуры для аддона
#   tools/preview/*.png       — превью (просто картинка, в игру не идёт)
#===========================================================================

import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIN_DIR = os.path.join(ROOT, "AdminToolsRU", "skin")
PREVIEW_DIR = os.path.join(ROOT, "tools", "preview")


#---------------------------------------------------------------------------
# Запись TGA: 32 бита (BGRA), origin снизу-слева, без сжатия
#---------------------------------------------------------------------------
def write_tga(path, width, height, pixels):
    """pixels: список строк сверху вниз, каждая — список (r, g, b, a)."""
    header = struct.pack(
        "<BBBHHBHHHHBB",
        0,      # длина поля ID
        0,      # нет цветовой карты
        2,      # тип: несжатый true-color
        0, 0, 0,
        0, 0,   # X/Y origin
        width, height,
        32,     # бит на пиксель
        8,      # 8 бит альфы, origin снизу-слева (0x08)
    )
    body = bytearray()
    for row in reversed(pixels):          # TGA хранит снизу вверх
        for (r, g, b, a) in row:
            body += bytes((b, g, r, a))
    with open(path, "wb") as f:
        f.write(header)
        f.write(body)


#---------------------------------------------------------------------------
# Запись PNG (только для превью, чтобы посмотреть глазами)
#---------------------------------------------------------------------------
def write_png(path, width, height, pixels):
    raw = bytearray()
    for row in pixels:
        raw.append(0)  # фильтр None
        for (r, g, b, a) in row:
            raw += bytes((r, g, b, a))

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


#---------------------------------------------------------------------------
# Текстуры
#---------------------------------------------------------------------------
def tex_button(alpha_top, alpha_bottom, size=64):
    """Вертикальный градиент для фона кнопки (тинтуется цветом в игре)."""
    out = []
    for y in range(size):
        t = y / (size - 1)
        a = alpha_top + (alpha_bottom - alpha_top) * t
        # лёгкий блик сверху: первые 6% высоты чуть светлее
        if t < 0.06:
            a = min(1.0, a + 26 / 255.0)
        out.append([(255, 255, 255, int(round(a * 255)))] * size)
    return out


def tex_panel(size=64):
    """Фон панели: почти ровный, с очень мягким затемнением книзу."""
    out = []
    for y in range(size):
        t = y / (size - 1)
        a = 1.0 - 0.10 * t
        # мягкий блик у верхней кромки
        if t < 0.04:
            a = min(1.0, a + 0.06)
        out.append([(255, 255, 255, int(round(a * 255)))] * size)
    return out


def tex_glow(size=128):
    """Радиальное свечение: для заголовка и активной вкладки."""
    out = []
    c = (size - 1) / 2.0
    for y in range(size):
        row = []
        for x in range(size):
            d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5 / c
            a = max(0.0, 1.0 - d)
            a = a ** 2.2
            row.append((255, 255, 255, int(round(a * 255))))
        out.append(row)
    return out


def tex_line(size=64):
    """Горизонтальная линия с растворяющимися краями — подчёркивание вкладки."""
    out = []
    for y in range(size):
        row = []
        for x in range(size):
            t = x / (size - 1)
            edge = min(t, 1 - t) * 2
            a = min(1.0, edge * 3) if y < 1 else (max(0.0, 1 - y / 3.0) * min(1.0, edge * 3))
            row.append((255, 255, 255, int(round(a * 255))))
        out.append(row)
    return out


#---------------------------------------------------------------------------
# Сборка
#---------------------------------------------------------------------------
def main():
    os.makedirs(SKIN_DIR, exist_ok=True)
    os.makedirs(PREVIEW_DIR, exist_ok=True)

    textures = {
        "btn-normal": tex_button(0.20, 0.07),
        "btn-hover":  tex_button(0.42, 0.18),
        "btn-pushed": tex_button(0.04, 0.12),
        "panel":      tex_panel(),
        "glow":       tex_glow(),
        "line":       tex_line(),
    }

    for name, pixels in textures.items():
        tga = os.path.join(SKIN_DIR, name + ".tga")
        write_tga(tga, len(pixels[0]), len(pixels), pixels)
        print("  %-46s %6d байт" % (os.path.relpath(tga, ROOT), os.path.getsize(tga)))

    # Превью: лист с образцами на тёмном фоне, как в игре
    scale, pad = 3, 8
    tiles = []
    for name in ("btn-normal", "btn-hover", "btn-pushed", "panel", "glow", "line"):
        pixels = textures[name]
        up = []
        for row in pixels:
            up.extend([row] * scale)
        tiles.append(up)

    W = max(len(t[0]) for t in tiles) + pad * 2
    H = sum(len(t) for t in tiles) + pad * (len(tiles) + 1)
    canvas = [[(16, 18, 24, 255)] * W for _ in range(H)]

    y = pad
    for tile in tiles:
        for ty, row in enumerate(tile):
            for tx, (r, g, b, a) in enumerate(row):
                if a:
                    lum = a / 255.0
                    canvas[y + ty][pad + tx] = (int(90 * lum), int(200 * lum), int(240 * lum), 255)
        y += len(tile) + pad

    preview = os.path.join(PREVIEW_DIR, "skin-preview.png")
    write_png(preview, W, H, canvas)
    print("\nПревью: %s" % os.path.relpath(preview, ROOT))


if __name__ == "__main__":
    main()
