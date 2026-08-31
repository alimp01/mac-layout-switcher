#!/usr/bin/env python3
"""make-icns.py — собирает Resources/AppIcon.icns из Resources/AppIcon.svg.

Зачем свой скрипт: сборочная машина — Linux, эппловского iconutil здесь нет.
К счастью, современный формат .icns тривиален — это контейнер PNG-чанков:

    заголовок:  b'icns' + uint32 BE (полная длина файла)
    далее чанки: [4 байта тип][uint32 BE длина чанка ВКЛЮЧАЯ 8-байтовый
                 заголовок чанка][PNG-данные]

Типы чанков с PNG-содержимым по размерам (пиксели стороны квадрата):
    icp4=16, icp5=32, icp6=64, ic07=128, ic08=256, ic09=512, ic10=1024

Рендер SVG→PNG — cairosvg (установлен на машине; новых зависимостей нет).
После записи скрипт сам перечитывает файл и парсит чанки обратно (self-check):
валидный заголовок, ровно 7 чанков, каждый — PNG нужного размера.

Запуск (из любого cwd):  python3 tools/make-icns.py
Перезапускать после каждой правки Resources/AppIcon.svg.
"""

import struct
import sys
from pathlib import Path

import cairosvg

ROOT = Path(__file__).resolve().parent.parent
SVG_PATH = ROOT / "Resources" / "AppIcon.svg"
ICNS_PATH = ROOT / "Resources" / "AppIcon.icns"

# (тип чанка, сторона квадрата в пикселях) — порядок от меньшего к большему.
CHUNK_TYPES = [
    (b"icp4", 16),
    (b"icp5", 32),
    (b"icp6", 64),
    (b"ic07", 128),
    (b"ic08", 256),
    (b"ic09", 512),
    (b"ic10", 1024),
]

PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


def render_pngs(svg_bytes: bytes) -> list[tuple[bytes, int, bytes]]:
    """Рендерит SVG в PNG всех нужных размеров. → [(тип, размер, png)]."""
    out = []
    for ctype, size in CHUNK_TYPES:
        png = cairosvg.svg2png(
            bytestring=svg_bytes, output_width=size, output_height=size
        )
        out.append((ctype, size, png))
    return out


def build_icns(pngs: list[tuple[bytes, int, bytes]]) -> bytes:
    """Складывает PNG-чанки в контейнер icns."""
    body = b""
    for ctype, _size, png in pngs:
        body += ctype + struct.pack(">I", 8 + len(png)) + png
    return b"icns" + struct.pack(">I", 8 + len(body)) + body


def png_dimensions(png: bytes) -> tuple[int, int]:
    """Ширина/высота из IHDR (первый чанк PNG, offset 16)."""
    if not png.startswith(PNG_MAGIC) or png[12:16] != b"IHDR":
        raise ValueError("не PNG или нестандартный первый чанк")
    w, h = struct.unpack(">II", png[16:24])
    return w, h


def self_check(path: Path) -> None:
    """Перечитывает готовый .icns и парсит чанки обратно.

    Проверяет независимо от кода сборки: магию, заявленную длину, состав
    чанков (типы и порядок из CHUNK_TYPES) и что каждый PNG — реально PNG
    ожидаемого размера.
    """
    data = path.read_bytes()
    if data[:4] != b"icns":
        raise SystemExit(f"self-check: файл не начинается с b'icns': {data[:4]!r}")
    (declared_len,) = struct.unpack(">I", data[4:8])
    if declared_len != len(data):
        raise SystemExit(
            f"self-check: длина в заголовке {declared_len} != размер файла {len(data)}"
        )

    parsed = []
    offset = 8
    while offset < len(data):
        if offset + 8 > len(data):
            raise SystemExit(f"self-check: обрезанный заголовок чанка @ {offset}")
        ctype = data[offset : offset + 4]
        (clen,) = struct.unpack(">I", data[offset + 4 : offset + 8])
        if clen < 8 or offset + clen > len(data):
            raise SystemExit(f"self-check: некорректная длина чанка {ctype!r}: {clen}")
        payload = data[offset + 8 : offset + clen]
        parsed.append((ctype, payload))
        offset += clen

    expected = [(t, s) for t, s in CHUNK_TYPES]
    if [t for t, _ in parsed] != [t for t, _ in expected]:
        raise SystemExit(
            f"self-check: состав чанков {[t for t, _ in parsed]} != {[t for t, _ in expected]}"
        )
    for (ctype, payload), (_t, size) in zip(parsed, expected):
        w, h = png_dimensions(payload)
        if (w, h) != (size, size):
            raise SystemExit(
                f"self-check: чанк {ctype.decode()} содержит PNG {w}x{h}, ожидалось {size}x{size}"
            )
    print(f"self-check OK: {len(parsed)} чанков, {len(data)} байт")


def main() -> None:
    if not SVG_PATH.exists():
        raise SystemExit(f"Нет исходника: {SVG_PATH}")
    svg_bytes = SVG_PATH.read_bytes()

    print(f"==> Рендерю {SVG_PATH.name} в PNG {[s for _, s in CHUNK_TYPES]}")
    pngs = render_pngs(svg_bytes)
    icns = build_icns(pngs)
    ICNS_PATH.write_bytes(icns)
    print(f"==> Записан {ICNS_PATH} ({len(icns)} байт)")

    self_check(ICNS_PATH)


if __name__ == "__main__":
    main()
