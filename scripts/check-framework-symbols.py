#!/usr/bin/env python3

import os
import struct
import sys
from pathlib import Path

PREFIX = b"singularity_"
SHT_DYNSYM = 11


def dynamic_symbols(data: bytes) -> tuple[set[bytes], set[bytes]]:
    if data[:4] != b"\x7fELF" or data[4] != 2 or data[5] != 1:
        return set(), set()
    shoff = struct.unpack_from("<Q", data, 0x28)[0]
    shentsize, shnum = struct.unpack_from("<HH", data, 0x3A)
    sections = [
        struct.unpack_from("<IIQQQQIIQQ", data, shoff + index * shentsize)
        for index in range(shnum)
    ]
    undefined: set[bytes] = set()
    defined: set[bytes] = set()

    for section in sections:
        if section[1] != SHT_DYNSYM:
            continue
        strings = sections[section[6]][4]
        for index in range(section[5] // 24):
            name, _, _, shndx, _, _ = struct.unpack_from(
                "<IBBHQQ", data, section[4] + index * 24
            )
            start = strings + name
            symbol = data[start:data.index(b"\0", start)]
            if not symbol.startswith(PREFIX):
                continue
            (undefined if shndx == 0 else defined).add(symbol)

    return undefined, defined


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: check-framework-symbols.py TARGET_DIR", file=sys.stderr)
        return 2

    root = Path(sys.argv[1])
    needed: dict[Path, set[bytes]] = {}
    provided: set[bytes] = set()

    for top in ("usr/bin", "usr/sbin", "usr/libexec", "usr/lib"):
        if (root / top).is_symlink():
            continue
        for base, _, files in os.walk(root / top):
            for name in files:
                path = Path(base, name)
                if path.is_symlink() or not path.is_file():
                    continue
                try:
                    data = path.read_bytes()
                except OSError:
                    continue
                try:
                    undefined, defined = dynamic_symbols(data)
                except (struct.error, ValueError, IndexError):
                    continue
                provided |= defined
                if undefined:
                    needed[path] = undefined

    failed = 0
    for path, symbols in sorted(needed.items()):
        missing = sorted(symbols - provided)
        if not missing:
            continue
        failed += 1
        shown = ", ".join(symbol.decode() for symbol in missing[:5])
        print(
            f"{path.relative_to(root)}: {len(missing)} unresolved ({shown})",
            file=sys.stderr,
        )

    if failed:
        print(f"{failed} files need framework symbols nothing provides", file=sys.stderr)
        return 1
    print(f"[singularity] framework symbols resolved for {len(needed)} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
