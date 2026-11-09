#!/usr/bin/env python3
import struct
import sys


def align(v, a):
    return (v + a - 1) // a * a


def main():
    if len(sys.argv) < 4 or (len(sys.argv) - 2) % 2:
        sys.exit("usage: pe-add-sections.py IMAGE NAME FILE [NAME FILE ...]")
    path = sys.argv[1]
    pairs = list(zip(sys.argv[2::2], sys.argv[3::2]))
    data = bytearray(open(path, "rb").read())

    pe = struct.unpack_from("<I", data, 0x3C)[0]
    if data[pe:pe + 4] != b"PE\0\0":
        sys.exit(f"{path}: not a PE image")
    coff = pe + 4
    nsec, = struct.unpack_from("<H", data, coff + 2)
    opt_size, = struct.unpack_from("<H", data, coff + 16)
    opt = coff + 20
    if struct.unpack_from("<H", data, opt)[0] != 0x20B:
        sys.exit(f"{path}: not PE32+")
    sect_align, file_align = struct.unpack_from("<II", data, opt + 32)
    size_headers, = struct.unpack_from("<I", data, opt + 60)
    table = opt + opt_size

    end_va = 0
    first_raw = len(data)
    for i in range(nsec):
        e = table + i * 40
        vsize, va, rawsize, rawptr = struct.unpack_from("<IIII", data, e + 8)
        end_va = max(end_va, va + max(vsize, rawsize))
        if rawsize:
            first_raw = min(first_raw, rawptr)

    if table + (nsec + len(pairs)) * 40 > min(size_headers, first_raw):
        sys.exit(f"{path}: no room in the section table for {len(pairs)} more sections")

    data.extend(b"\0" * (align(len(data), file_align) - len(data)))
    for name, src in pairs:
        payload = open(src, "rb").read()
        if len(name.encode()) > 8:
            sys.exit(f"section name too long: {name}")
        va = align(end_va, sect_align)
        rawptr = len(data)
        rawsize = align(len(payload), file_align)
        data.extend(payload + b"\0" * (rawsize - len(payload)))
        e = table + nsec * 40
        struct.pack_into("<8sIIIIIIHHI", data, e, name.encode().ljust(8, b"\0"),
                         len(payload), va, rawsize, rawptr, 0, 0, 0, 0, 0x40000040)
        nsec += 1
        end_va = va + len(payload)

    struct.pack_into("<H", data, coff + 2, nsec)
    struct.pack_into("<I", data, opt + 56, align(end_va, sect_align))
    struct.pack_into("<I", data, opt + 64, 0)
    open(path, "wb").write(data)


if __name__ == "__main__":
    main()
