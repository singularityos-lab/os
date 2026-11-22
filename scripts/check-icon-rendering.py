#!/usr/bin/env python3

import os
import re
import struct
import subprocess
import sys
import zlib
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

SIZE = 96
VISIBLE = 40
KEPT = 0.9
FILTER_REFERENCE = re.compile(rb"\s+filter\s*=\s*([\"'])url\([^\"']*\)\1")


def alpha_channel(png: bytes) -> bytes:
    if png[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    width, height, depth, colour = struct.unpack_from(">IIBB", png, 16)
    if depth != 8 or colour not in (2, 6):
        raise ValueError("unexpected PNG layout")
    if colour == 2:
        return b"\xff" * (width * height)

    packed = b""
    offset = 8
    while offset < len(png):
        length, kind = struct.unpack_from(">I4s", png, offset)
        if kind == b"IDAT":
            packed += png[offset + 8:offset + 8 + length]
        offset += length + 12

    raw = zlib.decompress(packed)
    stride = width * 4 + 1
    previous = [0] * width
    alpha = bytearray()
    for row in range(height):
        line = raw[row * stride:(row + 1) * stride]
        mode = line[0]
        current: list[int] = []
        for column, value in enumerate(line[4::4]):
            left = current[-1] if column else 0
            above = previous[column]
            corner = previous[column - 1] if column else 0
            if mode == 1:
                value += left
            elif mode == 2:
                value += above
            elif mode == 3:
                value += (left + above) // 2
            elif mode == 4:
                guess = left + above - corner
                value += min((left, above, corner), key=lambda near: abs(guess - near))
            current.append(value & 0xFF)
        alpha.extend(current)
        previous = current
    return bytes(alpha)


def coverage(renderer: str, svg: bytes, directory: Path) -> int:
    result = subprocess.run(
        [renderer, "-w", str(SIZE), "-h", str(SIZE)],
        input=svg,
        cwd=directory,
        capture_output=True,
    )
    if result.returncode:
        raise ValueError(result.stderr.decode(errors="replace").strip())
    return sum(value > VISIBLE for value in alpha_channel(result.stdout))


def defect(renderer: str, path: Path) -> str | None:
    svg = path.read_bytes()
    try:
        drawn = coverage(renderer, svg, path.parent)
        if not drawn:
            return "renders empty"
        unfiltered = FILTER_REFERENCE.sub(b"", svg)
        if unfiltered == svg:
            return None
        expected = coverage(renderer, unfiltered, path.parent)
    except ValueError as error:
        return f"does not render ({error})"
    if drawn < KEPT * expected:
        return f"filters erase {100 - drawn * 100 // expected}% of it"
    return None


def colour_icons(root: Path) -> list[Path]:
    icons: list[Path] = []
    for base, _, files in os.walk(root):
        for name in files:
            if not name.endswith(".svg") or "-symbolic" in name:
                continue
            path = Path(base, name)
            if not path.is_symlink():
                icons.append(path)
    return sorted(icons)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: check-icon-rendering.py RSVG_CONVERT TARGET_DIR", file=sys.stderr)
        return 2

    renderer, root = sys.argv[1], Path(sys.argv[2])
    icons = colour_icons(root / "usr/share/icons")
    if not icons:
        print("no colour icons found to render", file=sys.stderr)
        return 1

    with ThreadPoolExecutor(os.cpu_count()) as pool:
        defects = list(pool.map(lambda path: defect(renderer, path), icons))

    failed = 0
    for path, problem in zip(icons, defects):
        if problem:
            failed += 1
            print(f"{path.relative_to(root)}: {problem}", file=sys.stderr)

    if failed:
        print(f"{failed} icons render broken", file=sys.stderr)
        return 1
    print(f"[singularity] {len(icons)} colour icons render complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())
