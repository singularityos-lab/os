#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor


def kept(rel, keep):
    return any(rel == k or rel.startswith(k + "/") for k in keep)


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: compress-firmware.py DIR [KEEP_PREFIX...]")
    root = os.path.realpath(sys.argv[1])
    keep = [k.strip("/") for k in sys.argv[2:]]
    xz = os.environ.get("XZ")
    if not xz or not os.access(xz, os.X_OK):
        xz = shutil.which("xz")
    if not xz:
        sys.exit("compress-firmware: xz not found")

    files = []
    links = []
    for d, dirs, names in os.walk(root):
        for n in names + [x for x in dirs if os.path.islink(os.path.join(d, x))]:
            p = os.path.join(d, n)
            rel = os.path.relpath(p, root)
            if os.path.islink(p):
                links.append(p)
            elif os.path.isfile(p) and not kept(rel, keep) and not n.endswith(".xz"):
                files.append(p)

    squeezed = set(files)
    renames = []
    for p in links:
        real = os.path.realpath(p)
        if real in squeezed:
            renames.append((p, os.readlink(p)))

    def squeeze(p):
        subprocess.run([xz, "-q", "-f", "-T1", "--check=crc32", p], check=True)

    with ThreadPoolExecutor(max_workers=os.cpu_count() or 1) as pool:
        list(pool.map(squeeze, files))

    for p, target in renames:
        os.unlink(p)
        os.symlink(target + ".xz", p + ".xz")

    broken = [os.path.relpath(os.path.join(d, n), root)
              for d, dirs, names in os.walk(root)
              for n in names + dirs
              if os.path.islink(os.path.join(d, n)) and not os.path.exists(os.path.join(d, n))]
    if broken:
        sys.exit("compress-firmware: broken links:\n" + "\n".join(sorted(broken)[:50]))
    print(f"compress-firmware: {len(files)} files and {len(renames)} links compressed, {len(keep)} trees kept as is")


if __name__ == "__main__":
    main()
