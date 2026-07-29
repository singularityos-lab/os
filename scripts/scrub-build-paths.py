#!/usr/bin/env python3

import os
import sys
from pathlib import Path


def replacement(prefix: bytes, label: bytes) -> bytes:
    if len(prefix) < len(label):
        raise ValueError(f"cannot replace short prefix {prefix!r}")
    return label + (b"/" * (len(prefix) - len(label)))


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: scrub-build-paths.py ROOT PREFIX...", file=sys.stderr)
        return 2

    root = Path(sys.argv[1])
    prefixes = sorted(
        {os.fsencode(os.path.abspath(value)) for value in sys.argv[2:]},
        key=len,
        reverse=True,
    )
    labels = [b"/buildroot", b"/source", b"/builder"]
    mappings = [
        (prefix, replacement(prefix, labels[min(index, len(labels) - 1)]))
        for index, prefix in enumerate(prefixes)
    ]
    changed = 0

    for base, _, files in os.walk(root):
        for name in files:
            path = Path(base, name)
            if path.is_symlink():
                continue
            try:
                data = path.read_bytes()
            except OSError:
                continue
            clean = data
            for old, new in mappings:
                clean = clean.replace(old, new)
            if clean != data:
                path.write_bytes(clean)
                changed += 1

    leaked = []
    for base, _, files in os.walk(root):
        for name in files:
            path = Path(base, name)
            if path.is_symlink():
                continue
            try:
                data = path.read_bytes()
            except OSError:
                continue
            if any(prefix in data for prefix in prefixes):
                leaked.append(str(path))

    if leaked:
        print("build path scrub failed:", file=sys.stderr)
        for path in leaked:
            print(path, file=sys.stderr)
        return 1

    print(f"[singularity] scrubbed host build paths from {changed} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
