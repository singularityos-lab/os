#!/usr/bin/env python3
import re
import sys

VISIBLE = 5

COLUMNS = ["review", "version", "date", "commit", "IMG", "ISO", "kc", "rfs", "rec",
           "sha", "sig", "vo", "nv", "amd", "portable"]


def header(channel):
    return f"""Builds of Sinty OS on the {channel} channel. Each row below is one build, identified by
the short commit it was built from. Assets are suffixed with that commit so builds
never overwrite each other and every row links its own set.

<details>
<summary>Column key</summary>

- **review**: sequential review identifier for this release table
- **version**: public Sinty OS version and build
- **date**: build date
- **commit**: the os source commit the build came from
- **IMG**: raw disk image, write to a USB stick or disk with `dd`
- **portable**: portable recovery and test image; it boots from removable media and can attach an installed data partition without changing deployment state
- **ISO**: hybrid ISO, boot in a VM or burn to install
- **kc**: kernelcache, the signed UKI (kernel + initramfs + cmdline) the loader boots
- **rfs**: read-only erofs Root, dm-verity sealed (ships alongside its `.hash` tree)
- **rec**: recovery kernelcache, the recovery-slot UKI
- **sha**: `SHA256SUMS` covering every asset in the build
- **sig**: detached signatures for **kc** and **rec** (kept next to the file each one signs; a `.sig` alone is useless)
- **vo**: verity-output, the dm-verity root hash and parameters for the Root
- **nv**: NVIDIA GPU firmware add-on bundle (OTA, dedicated NVIDIA GPUs)
- **amd**: AMD GPU firmware add-on bundle (OTA, dedicated AMD GPUs)

</details>

### Builds

{table_head()}
"""


def table_head():
    return "| " + " | ".join(COLUMNS) + " |\n|" + "|".join("-" * max(3, len(c) + 2) for c in COLUMNS) + "|"


def row(repo, tag, review, version, date, sha, firmware):
    base = f"https://github.com/{repo}/releases/download/{tag}"

    def link(label, name):
        return f"[{label}]({base}/{name})"

    nv = link("nv", f"sinty-firmware-nvidia-{sha}.tar.zst") if firmware else "-"
    amd = link("amd", f"sinty-firmware-amd-{sha}.tar.zst") if firmware else "-"
    cells = [
        review,
        version,
        date,
        f"[`{sha}`](https://github.com/{repo}/commit/{sha})",
        link("img", f"sinty-os-{sha}.img"),
        link("iso", f"sinty-os-{sha}.iso"),
        link("kc", f"kernelcache-{sha}.efi"),
        link("rfs", f"rootfs-{sha}.erofs"),
        link("rec", f"kernelcache-recovery-{sha}.efi"),
        link("sha", f"SHA256SUMS-{sha}.txt"),
        link("kc", f"kernelcache-{sha}.efi.sig") + ", " + link("rec", f"kernelcache-recovery-{sha}.efi.sig"),
        link("vo", f"verity-output-{sha}.txt"),
        nv,
        amd,
        link("portable", f"sinty-os-portable-{sha}.img"),
    ]
    return "| " + " | ".join(cells) + " |"


def insert(body, new_row, channel):
    if not re.search(r"(?m)^\| r\d+ \|", body):
        body = header(channel)
    lines = body.split("\n")
    rows = [i for i, l in enumerate(lines) if re.match(r"^\| r\d+ \|", l)]
    review = re.match(r"^\| (r\d+) \|", new_row).group(1)
    for i in rows:
        if lines[i].startswith(f"| {review} |"):
            raise SystemExit(f"{review} is already in the table")
    if not rows:
        head = next(i for i, l in enumerate(lines) if l.startswith("| review |"))
        lines.insert(head + 2, new_row)
        return "\n".join(lines)
    older = next((i for i, l in enumerate(lines) if l.startswith("<summary>Older builds")), None)
    visible = [i for i in rows if older is None or i < older]
    lines.insert(visible[0], new_row)
    visible = [i + 1 for i in visible]
    if len(visible) + 1 > VISIBLE:
        last = visible[-1]
        moved = lines.pop(last)
        if older is None:
            lines += ["", "<details>", "<summary>Older builds</summary>", "", table_head(), moved, "", "</details>"]
        else:
            older += 1
            older_rows = [i for i, l in enumerate(lines) if re.match(r"^\| r\d+ \|", l) and i > older - 1]
            lines.insert(older_rows[0] if older_rows else older + 3, moved)
    return "\n".join(lines)


def main():
    body_file, repo, tag, review, version, date, sha, firmware = sys.argv[1:9]
    body = open(body_file).read() if body_file != "-" else ""
    new_row = row(repo, tag, review, version, date, sha, firmware == "1")
    sys.stdout.write(insert(body, new_row, tag))


if __name__ == "__main__":
    main()
