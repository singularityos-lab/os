#!/usr/bin/env python3

import hashlib
import json
import os
import re
import struct
import sys
from pathlib import Path

LIBRARY_DIRS = (
    "usr/lib",
    "usr/local/lib",
    "usr/lib/sinty-framework",
    "usr/local/lib/fotone-proxy",
)
PRIVATE_NAMES = re.compile(
    r"(\.(key|p12|pfx)|^id_(rsa|ecdsa|ed25519)|^\.(env|netrc|git-credentials|git))$"
)
PRIVATE_KEY = re.compile(
    rb"-----BEGIN (?:[A-Z]+ )?PRIVATE KEY-----[\r\n]+"
    rb"(Proc-Type:|[A-Za-z0-9+/=\r\n]{40,})"
)
TOKENS = (
    re.compile(rb"gh[psor]_[A-Za-z0-9]{36}(?![A-Za-z0-9])"),
    re.compile(rb"github_pat_[A-Za-z0-9_]{60}"),
)
GNUTLS_SELFTEST_KEYS = {
    "0abce0c5fd3b863ee4d881dcc5382b334393868cef4c32e687d87ce334d456b8",
    "24a2416c5abbb67327599619c25906553b849d79cbc413e2a061f12de6718838",
    "30db3ea6d728b88c03c56388f64efb5bfe5e8d0ed3640482108ac79645304e6f",
    "518a21fe5a8a54f8f31d8913c3aa5be433ba94871630b3f85009c146bd3b844e",
    "6d03bbf47115fad00d6f990593a6465ca693d0f6d797721cfc94b0190349b50d",
    "8f642f0351e1761dd3f7d8934a2da0a5eacd7f8a2c0440d8e2bf58ff2a6e847d",
    "9ab6db67523ba6071fdb948b3ce38349ec08fb726f359abbbca33a3a84238ba2",
    "bbe1aa11658d78c055f3d4ea85c76fa05c5728b7ad033122f87ff5948b2a5123",
    "bf552d2ff30b20f0b0ee2bcc357a5ab68dbe899ae09a0071b097bee2d2434332",
    "c780c483da21d36753a9662fc03234d3fda795fe0bad451fbfa01dab43321ac5",
    "cadf1e62661d5d21a7fce2c80b3319022ee366137e4b302a7ea78b7f17d6f599",
    "f287c70b1db074fe73f73bfb1f09a8b0231e0d951d5bfd30a742bcb9de9195ab",
}
SHT_DYNAMIC = 6
SHT_DYNSYM = 11
DT_NEEDED = 1


def dynamic(data: bytes) -> tuple[list[str], list[str]]:
    shoff = struct.unpack_from("<Q", data, 0x28)[0]
    shentsize, shnum = struct.unpack_from("<HH", data, 0x3A)
    sections = [
        struct.unpack_from("<IIQQQQIIQQ", data, shoff + index * shentsize)
        for index in range(shnum)
    ]

    def text(section: tuple, offset: int) -> str:
        start = sections[section[6]][4] + offset
        return data[start:data.index(b"\0", start)].decode()

    exports: set[str] = set()
    needed: list[str] = []
    for section in sections:
        entries = range(section[4], section[4] + section[5], section[9] or 1)
        if section[1] == SHT_DYNSYM:
            for at in entries:
                name, info, _, shndx = struct.unpack_from("<IBBH", data, at)
                if name and shndx and info >> 4:
                    exports.add(text(section, name))
        elif section[1] == SHT_DYNAMIC:
            for at in entries:
                tag, value = struct.unpack_from("<qQ", data, at)
                if tag == DT_NEEDED:
                    needed.append(text(section, value))
    return sorted(exports), needed


def abi(target: Path) -> int:
    names: dict[str, str] = {}
    files: dict[str, dict] = {}
    for top in LIBRARY_DIRS:
        if not (target / top).is_dir():
            continue
        for path in sorted((target / top).iterdir()):
            if ".so" not in path.name:
                continue
            real = path
            for _ in range(16):
                if not real.is_symlink():
                    break
                link = os.readlink(real)
                real = target / link.lstrip("/") if link.startswith("/") else real.parent / link
            if not real.is_file():
                continue
            key = "/" + os.path.relpath(os.path.realpath(real), os.path.realpath(target))
            if key not in files:
                data = real.read_bytes()
                if data[:4] != b"\x7fELF" or data[4] != 2:
                    continue
                exports, needed = dynamic(data)
                files[key] = {
                    "sha256": hashlib.sha256(data).hexdigest(),
                    "exports": exports,
                    "needed": needed,
                }
            names.setdefault(path.name, key)
    json.dump({"names": names, "files": files}, sys.stdout, sort_keys=True)
    return 0


def holds_secret(data: bytes) -> bool:
    for match in PRIVATE_KEY.finditer(data):
        body = re.sub(rb"[\r\n]", b"", match.group(1))
        if hashlib.sha256(body).hexdigest() not in GNUTLS_SELFTEST_KEYS:
            return True
    return any(token.search(data) for token in TOKENS)


def audit(tree: Path) -> int:
    found = 0
    for base, dirs, files in os.walk(tree):
        for name in dirs + files:
            path = Path(base, name)
            reason = "private file name" if PRIVATE_NAMES.search(name) else ""
            if not reason and name in files and path.is_file() and not path.is_symlink():
                if holds_secret(path.read_bytes()):
                    reason = "private key or token"
            if reason:
                found += 1
                print(f"{path.relative_to(tree)}: {reason}", file=sys.stderr)
    if found:
        print(f"{found} files must not be published", file=sys.stderr)
        return 1
    print("[singularity] the SDK holds no keys or tokens")
    return 0


def relink(tree: Path, origin: str, sysroot: str) -> int:
    changed = dropped = 0
    for base, dirs, files in os.walk(tree):
        for name in dirs + files:
            path = Path(base, name)
            if not path.is_symlink() or not os.readlink(path).startswith("/"):
                continue
            link = os.readlink(path)
            if link.startswith(origin + "/"):
                destination = tree / link[len(origin) + 1:]
            elif path.is_relative_to(tree / sysroot):
                destination = tree / sysroot / link.lstrip("/")
            else:
                destination = None
            path.unlink()
            if destination is None or not os.path.lexists(destination):
                dropped += 1
                continue
            path.symlink_to(os.path.relpath(destination, path.parent))
            changed += 1
    print(f"[singularity] {changed} links made relative, {dropped} dropped")
    return 0


def main() -> int:
    match sys.argv[1:]:
        case ["abi", target]:
            return abi(Path(target))
        case ["audit", tree]:
            return audit(Path(tree))
        case ["relink", tree, origin, sysroot]:
            return relink(Path(tree), origin, sysroot)
    print("usage: sdk-tree.py abi TARGET | audit TREE | relink TREE ORIGIN SYSROOT", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
