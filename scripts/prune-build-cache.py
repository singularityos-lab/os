#!/usr/bin/env python3
import os
import re
import shutil
import sys

VERSION = re.compile(r"^(?P<name>.+?)-(?P<version>[0-9a-f]{40}|[0-9][0-9A-Za-z.+~_]*)$")


def superseded(build):
    groups = {}
    for entry in os.scandir(build):
        if not entry.is_dir(follow_symlinks=False):
            continue
        match = VERSION.match(entry.name)
        if not match:
            continue
        groups.setdefault(match["name"], []).append(entry)
    for name, entries in groups.items():
        if len(entries) < 2:
            continue
        entries.sort(key=lambda e: e.stat(follow_symlinks=False).st_mtime, reverse=True)
        yield from entries[1:]


def size(path):
    total = 0
    for root, _, files in os.walk(path):
        for f in files:
            try:
                total += os.lstat(os.path.join(root, f)).st_size
            except OSError:
                pass
    return total


def main():
    if len(sys.argv) not in (2, 3) or (len(sys.argv) == 3 and sys.argv[2] != "--dry-run"):
        sys.exit("usage: prune-build-cache.py BUILD_DIR [--dry-run]")
    build = sys.argv[1]
    dry = len(sys.argv) == 3
    freed = 0
    count = 0
    for entry in superseded(build):
        freed += size(entry.path)
        count += 1
        if not dry:
            shutil.rmtree(entry.path)
    print(f"{'would drop' if dry else 'dropped'} {count} superseded package builds, {freed / 2**30:.1f} GiB")


if __name__ == "__main__":
    main()
