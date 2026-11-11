#!/usr/bin/env python3
import functools
import os
import struct
import sys

MACHINES = {
    183: 0x0A03,
    62: 0x0303,
}
DT_SONAME = 14


def elf_info(path):
    try:
        with open(path, "rb") as f:
            head = f.read(64)
            if len(head) < 64 or head[:4] != b"\x7fELF" or head[4] != 2 or head[5] != 1:
                return None
            e_type, e_machine = struct.unpack_from("<HH", head, 16)
            if e_type != 3 or e_machine not in MACHINES:
                return None
            e_phoff = struct.unpack_from("<Q", head, 32)[0]
            e_phentsize, e_phnum = struct.unpack_from("<HH", head, 54)
            f.seek(e_phoff)
            phdrs = f.read(e_phentsize * e_phnum)
            loads = []
            dynamic = None
            for i in range(e_phnum):
                p_type, _, p_offset, p_vaddr, _, p_filesz = struct.unpack_from("<IIQQQQ", phdrs, i * e_phentsize)
                if p_type == 1:
                    loads.append((p_vaddr, p_offset, p_filesz))
                elif p_type == 2:
                    dynamic = (p_offset, p_filesz)
            soname = None
            if dynamic:
                f.seek(dynamic[0])
                dyn = f.read(dynamic[1])
                strtab = None
                name_off = None
                for i in range(0, len(dyn) - 15, 16):
                    tag, val = struct.unpack_from("<qQ", dyn, i)
                    if tag == 0:
                        break
                    if tag == 5:
                        strtab = val
                    elif tag == DT_SONAME:
                        name_off = val
                if strtab is not None and name_off is not None:
                    for vaddr, off, size in loads:
                        if vaddr <= strtab < vaddr + size:
                            f.seek(off + strtab - vaddr + name_off)
                            raw = f.read(4096)
                            soname = raw.split(b"\0", 1)[0].decode()
                            break
            return e_machine, soname
    except OSError:
        return None


def libcmp(a, b):
    i = j = 0
    while i < len(a):
        if a[i].isdigit():
            if j < len(b) and b[j].isdigit():
                si = i
                while i < len(a) and a[i].isdigit():
                    i += 1
                sj = j
                while j < len(b) and b[j].isdigit():
                    j += 1
                v1, v2 = int(a[si:i]), int(b[sj:j])
                if v1 != v2:
                    return v1 - v2
            else:
                return 1
        elif j < len(b) and b[j].isdigit():
            return -1
        else:
            c2 = b[j] if j < len(b) else "\0"
            if a[i] != c2:
                return ord(a[i]) - ord(c2)
            i += 1
            j += 1
    return 0 - (ord(b[j]) if j < len(b) else 0)


def resolve(root, path):
    seen = 0
    while os.path.islink(path) and seen < 40:
        link = os.readlink(path)
        if link.startswith("/"):
            path = os.path.join(root, link.lstrip("/"))
        else:
            path = os.path.join(os.path.dirname(path), link)
        seen += 1
    return path


def collect(root, dirs, machine):
    entries = {}
    real_dirs = set()
    for d in dirs:
        full = os.path.join(root, d.lstrip("/"))
        if not os.path.isdir(full):
            continue
        real = os.path.realpath(full)
        if real in real_dirs:
            continue
        real_dirs.add(real)
        found = {}
        for name in sorted(os.listdir(full)):
            if not (name.startswith("lib") or name.startswith("ld-")) or ".so" not in name:
                continue
            path = os.path.join(full, name)
            is_link = os.path.islink(path)
            target = resolve(root, path) if is_link else path
            if not os.path.isfile(target):
                continue
            info = elf_info(target)
            if info is None or info[0] != machine:
                continue
            soname = info[1] or name
            if is_link and name != soname and not (name.endswith(".so") and soname.startswith(name)):
                is_link = False
            if is_link:
                soname = name
            have = found.get(soname)
            if have is None or (not is_link and have[1]) or (is_link == have[1] and libcmp(have[0], name) < 0):
                found[soname] = (name, is_link)
        for soname, (name, _) in found.items():
            if soname in entries:
                continue
            pick = soname if os.path.lexists(os.path.join(full, soname)) else name
            entries[soname] = "/" + d.strip("/") + "/" + pick
    return entries


def write_cache(out, entries, flags):
    order = sorted(entries.items(), key=functools.cmp_to_key(lambda x, y: libcmp(y[0], x[0])))
    header = 48
    table = bytearray()
    offsets = {}
    base = header + 24 * len(order)

    def add(s):
        if s not in offsets:
            offsets[s] = base + len(table)
            table.extend(s.encode() + b"\0")
        return offsets[s]

    rows = bytearray()
    for key, value in order:
        rows += struct.pack("<iIIIQ", flags, add(key), add(value), 0, 0)
    head = b"glibc-ld.so.cache" + b"1.1" + struct.pack("<IIB3xI12x", len(order), len(table), 2, 0)
    tmp = out + ".tmp"
    with open(tmp, "wb") as f:
        f.write(head + rows + table)
    os.replace(tmp, out)
    return len(order)


def main():
    if len(sys.argv) < 4:
        sys.exit("usage: ld-cache.py ROOT aarch64|x86_64 DIR...")
    root, arch, dirs = sys.argv[1], sys.argv[2], sys.argv[3:]
    machine = {"aarch64": 183, "x86_64": 62}[arch]
    entries = collect(root, dirs, machine)
    os.makedirs(os.path.join(root, "etc"), exist_ok=True)
    n = write_cache(os.path.join(root, "etc/ld.so.cache"), entries, MACHINES[machine])
    print(f"{n} libs in {root}/etc/ld.so.cache")


if __name__ == "__main__":
    main()
