#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import re
import stat
import struct
import sys
import xml.etree.ElementTree as ET

CLASSES = {0: "silent", 1: "reload", 2: "relogin"}
REBOOT = 3
ANCHOR = "/usr/lib/atomloops/live"
SHT_DYNSYM = 11


def glob_regex(pattern):
    out = []
    i = 0
    while i < len(pattern):
        if pattern.startswith("**", i):
            out.append(".*")
            i += 2
        elif pattern[i] == "*":
            out.append("[^/]*")
            i += 1
        elif pattern[i] == "?":
            out.append("[^/]")
            i += 1
        else:
            out.append(re.escape(pattern[i]))
            i += 1
    return re.compile("^" + "".join(out) + "$")


def load_table(path):
    rules = []
    with open(path) as f:
        for number, line in enumerate(f, 1):
            fields = line.split()
            if not fields:
                continue
            if len(fields) not in (2, 3) or fields[0] not in "0123" or not fields[1].startswith("/"):
                raise SystemExit(f"{path}:{number}: expected 'STAGE /pattern [abi:STAGE|keys:STAGE]'")
            qualifier = None
            if len(fields) == 3:
                kind, _, raise_to = fields[2].partition(":")
                if kind not in ("abi", "keys") or raise_to not in "0123" or not raise_to:
                    raise SystemExit(f"{path}:{number}: unknown qualifier {fields[2]}")
                qualifier = (kind, int(raise_to))
            rules.append((int(fields[0]), glob_regex(fields[1]), qualifier, fields[1]))
    return rules


def match(rules, path):
    for rule in rules:
        if rule[1].match(path):
            return rule
    return None


def dynamic_symbols(data):
    if data[:4] != b"\x7fELF" or data[4] != 2 or data[5] != 1:
        return None
    shoff = struct.unpack_from("<Q", data, 0x28)[0]
    shentsize, shnum = struct.unpack_from("<HH", data, 0x3A)
    sections = [struct.unpack_from("<IIQQQQIIQQ", data, shoff + i * shentsize) for i in range(shnum)]
    defined = set()
    for section in sections:
        if section[1] != SHT_DYNSYM:
            continue
        strings = sections[section[6]][4]
        for i in range(section[5] // 24):
            name, info, _, shndx, _, _ = struct.unpack_from("<IBBHQQ", data, section[4] + i * 24)
            if shndx == 0 or name == 0 or info >> 4 == 0:
                continue
            start = strings + name
            defined.add(data[start:data.index(b"\0", start)].decode("utf-8", "replace"))
    return sorted(defined)


def schema_keys(data):
    try:
        root = ET.fromstring(data)
    except ET.ParseError:
        return None
    keys = []
    for schema in root.iter("schema"):
        for key in schema.iter("key"):
            keys.append(schema.get("id", "") + "/" + key.get("name", ""))
    return sorted(keys)


def list_root(root, rules):
    entries = []
    for base, dirs, files in os.walk(root):
        dirs.sort()
        rel = "/" + os.path.relpath(base, root) if base != root else ""
        for name in sorted(dirs):
            full = os.path.join(base, name)
            if os.path.islink(full):
                files.append(name)
                continue
            entries.append([rel + "/" + name, "d", oct(stat.S_IMODE(os.lstat(full).st_mode)), "", None])
        for name in sorted(set(files)):
            full = os.path.join(base, name)
            path = rel + "/" + name
            st = os.lstat(full)
            mode = oct(stat.S_IMODE(st.st_mode))
            if stat.S_ISLNK(st.st_mode):
                entries.append([path, "l", mode, os.readlink(full), None])
                continue
            if not stat.S_ISREG(st.st_mode):
                entries.append([path, "o", mode, oct(st.st_mode), None])
                continue
            with open(full, "rb") as f:
                data = f.read()
            extra = None
            rule = match(rules, path)
            if rule and rule[2]:
                extra = dynamic_symbols(data) if rule[2][0] == "abi" else schema_keys(data)
            entries.append([path, "f", mode, hashlib.sha256(data).hexdigest(), extra])
    entries.sort(key=lambda e: e[0])
    return entries


def read_list(path):
    entries = {}
    with open(path) as f:
        for line in f:
            if line.strip():
                e = json.loads(line)
                entries[e[0]] = e
    return entries


def decide(rules, old, new):
    reasons = []
    if ANCHOR not in old or ANCHOR not in new:
        reasons.append([ANCHOR, REBOOT, "the previous release cannot switch its root live"])
    for path in sorted(set(old) | set(new)):
        a, b = old.get(path), new.get(path)
        if a and b and a[1:4] == b[1:4]:
            continue
        if (a and a[1] == "d") and (not b or b[1] == "d"):
            continue
        if b and b[1] == "d" and not a:
            continue
        rule = match(rules, path)
        if rule is None:
            reasons.append([path, REBOOT, "not covered by the stage table"])
            continue
        stage, why = rule[0], rule[3]
        if rule[2]:
            kind, raise_to = rule[2]
            before = set(a[4] or []) if a and a[1] == "f" else set()
            after = set(b[4] or []) if b and b[1] == "f" else set()
            gone = before - after
            if gone and raise_to > stage:
                stage = raise_to
                what = "symbols" if kind == "abi" else "settings keys"
                why = f"{rule[3]}: {len(gone)} {what} removed ({sorted(gone)[0]})"
        reasons.append([path, stage, why])
    stage = max([r[1] for r in reasons], default=0)
    return stage, reasons


def main():
    parser = argparse.ArgumentParser(description="Work out how a Sinty OS release applies over the previous one.")
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("list", help="list the files of an extracted root")
    p.add_argument("--table", required=True)
    p.add_argument("root")
    p = sub.add_parser("decide", help="compare two file lists against the stage table")
    p.add_argument("--table", required=True)
    p.add_argument("--old", required=True)
    p.add_argument("--new", required=True)
    p.add_argument("--min-stage", type=int, default=0)
    args = parser.parse_args()
    rules = load_table(args.table)
    if args.cmd == "list":
        for e in list_root(args.root, rules):
            print(json.dumps(e, separators=(",", ":")))
        return 0
    stage, reasons = decide(rules, read_list(args.old), read_list(args.new))
    stage = max(stage, args.min_stage)
    top = sorted(reasons, key=lambda r: -r[1])
    print(json.dumps({
        "stage": stage,
        "class": CLASSES.get(stage, ""),
        "changed": len(reasons),
        "highest": [r for r in top if r[1] == stage][:40],
    }, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
