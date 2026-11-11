#!/usr/bin/env python3
import argparse
import hashlib
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.request

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LISTS = {"": "TARGET_DIR", "-staging": "STAGING_DIR", "-images": "BINARIES_DIR", "-host": "HOST_DIR"}
STAMPS = [".stamp_downloaded", ".stamp_extracted", ".stamp_patched", ".stamp_configured", ".stamp_built",
          ".stamp_host_installed", ".stamp_staging_installed", ".stamp_images_installed",
          ".stamp_target_installed", ".stamp_installed"]
GLOBAL_CONFIG = re.compile(r"^BR2_(ARCH|NORMALIZED_ARCH|aarch64|x86_64|cortex|x86_|ARM_|GCC_|TOOLCHAIN_|BINUTILS_|"
                           r"KERNEL_HEADERS|PACKAGE_GLIBC|OPTIMIZE_|ENABLE_LTO|SSP_|FORTIFY_|RELRO_|PIC_PIE|"
                           r"SHARED_|STATIC_|ENABLE_DEBUG|STRIP_|TARGET_OPTIMIZATION|USE_WCHAR|INSTALL_LIBSTDCPP)")


def make_vars(build_dir, names):
    wanted = []
    for n in names:
        u = n.upper().replace("-", "_")
        wanted += [u + "_DIR", u + "_PKGDIR", u + "_VERSION"]
    wanted += list(LISTS.values()) + ["BR2_VERSION"]
    out = subprocess.run(["make", "-s", "-C", os.path.join(REPO_DIR, "buildroot-src"), "O=" + build_dir,
                          "BR2_EXTERNAL=" + REPO_DIR, "printvars", "VARS=" + " ".join(wanted), "QUOTED_VARS=YES"],
                         capture_output=True, text=True, check=True).stdout
    vals = {}
    for line in out.splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            vals[k.strip()] = v.strip().strip("'")
    return vals


def package_key(name, vals, config_lines, arch):
    u = name.upper().replace("-", "_")
    h = hashlib.sha256()
    h.update(("%s\n%s\n%s\n" % (vals.get("BR2_VERSION", ""), arch, os.path.basename(vals[u + "_DIR"]))).encode())
    pkgdir = vals.get(u + "_PKGDIR", "")
    if pkgdir and os.path.isdir(pkgdir):
        for root, dirs, files in sorted(os.walk(pkgdir)):
            dirs.sort()
            for f in sorted(files):
                p = os.path.join(root, f)
                h.update(os.path.relpath(p, pkgdir).encode())
                with open(p, "rb") as fh:
                    h.update(fh.read())
    base = u[5:] if u.startswith("HOST_") else u
    syms = ("BR2_PACKAGE_%s=" % base, "BR2_PACKAGE_%s_" % base, "BR2_PACKAGE_HOST_%s" % base)
    for line in config_lines:
        if line.startswith(syms) or GLOBAL_CONFIG.match(line):
            h.update(line.encode())
    return h.hexdigest()[:16]


def load_config(build_dir):
    with open(os.path.join(build_dir, ".config")) as f:
        return sorted(l for l in f.read().splitlines() if l.startswith("BR2_"))


def asset_name(name, arch, key):
    return "%s-%s-%s.tar.zst" % (name, arch, key)


def save(args, names, vals, config, arch):
    os.makedirs(args.out, exist_ok=True)
    have = set(args.skip.split(",")) if args.skip else set()
    for name in names:
        u = name.upper().replace("-", "_")
        pdir = vals.get(u + "_DIR", "")
        if not pdir or not os.path.exists(os.path.join(pdir, ".stamp_installed")):
            print("skip %s: not built" % name)
            continue
        if os.path.exists(os.path.join(pdir, ".pkg-cache-asset")):
            continue
        key = package_key(name, vals, config, arch)
        asset = asset_name(name, arch, key)
        if asset in have:
            print("skip %s: %s already cached" % (name, asset))
            continue
        manifest = {"name": name, "dir": os.path.basename(pdir), "key": key, "arch": arch,
                    "stamps": [s for s in STAMPS if os.path.exists(os.path.join(pdir, s))], "lists": {}}
        with tempfile.TemporaryDirectory(dir=args.work) as tmp:
            tar_path = os.path.join(tmp, "p.tar")
            count = 0
            with tarfile.open(tar_path, "w") as tar:
                for suffix, root_var in LISTS.items():
                    lst = os.path.join(pdir, ".files-list%s.txt" % suffix)
                    if not os.path.exists(lst):
                        continue
                    root = vals[root_var]
                    paths = []
                    with open(lst) as f:
                        for line in f:
                            rel = line.rstrip("\n").split(",", 1)[-1]
                            full = os.path.join(root, rel)
                            if os.path.lexists(full):
                                tar.add(full, arcname="%s/%s" % (root_var, os.path.normpath(rel)), recursive=False)
                                paths.append(rel)
                                count += 1
                    manifest["lists"][suffix] = paths
                data = json.dumps(manifest).encode()
                info = tarfile.TarInfo("manifest.json")
                info.size = len(data)
                tar.addfile(info, io.BytesIO(data))
            out = os.path.join(args.out, asset)
            subprocess.run(["zstd", "-q", "-T0", "-10", "-f", tar_path, "-o", out], check=True)
            print("saved %s: %d files, %d MB" % (asset, count, os.path.getsize(out) // 1048576))


def unpack(zst, tmp):
    tar_path = os.path.join(tmp, "p.tar")
    subprocess.run(["zstd", "-q", "-d", "-f", zst, "-o", tar_path], check=True)
    stage = os.path.join(tmp, "x")
    with tarfile.open(tar_path) as tar:
        tar.extractall(stage, filter="tar")
    with open(os.path.join(stage, "manifest.json")) as f:
        return stage, json.load(f)


def copy_roots(stage, vals, roots):
    for root_var in roots:
        src = os.path.join(stage, root_var)
        if os.path.isdir(src):
            subprocess.run(["cp", "-a", "--remove-destination", src + "/.", vals[root_var] + "/"], check=True)


def touch_stamps(pdir, stamps):
    now = time.time()
    for i, s in enumerate(stamps):
        p = os.path.join(pdir, s)
        open(p, "w").close()
        os.utime(p, (now + i, now + i))


def restore(args, names, vals, config, arch):
    os.makedirs(args.store, exist_ok=True)
    restored = 0
    for name in names:
        u = name.upper().replace("-", "_")
        pdir = vals.get(u + "_DIR", "")
        if not pdir:
            continue
        marker = os.path.join(pdir, ".pkg-cache-asset")
        if os.path.exists(pdir):
            if not os.path.exists(marker):
                print("keep %s: built in this tree" % name)
                continue
            missing = [s for s in (".stamp_target_installed", ".stamp_images_installed")
                       if not os.path.exists(os.path.join(pdir, s))]
            with open(marker) as f:
                zst = os.path.join(args.store, f.read().strip())
            with tempfile.TemporaryDirectory(dir=args.work) as tmp:
                stage, manifest = unpack(zst, tmp)
                if not [s for s in missing if s in manifest["stamps"]]:
                    continue
                copy_roots(stage, vals, ["TARGET_DIR", "BINARIES_DIR"])
                touch_stamps(pdir, [s for s in manifest["stamps"] if s in missing] + [".stamp_installed"])
            print("reinstalled %s into the target from %s" % (name, os.path.basename(zst)))
            continue
        if not name.startswith("host-") and "BR2_PACKAGE_%s=y" % u not in config:
            continue
        key = package_key(name, vals, config, arch)
        asset = asset_name(name, arch, key)
        zst = os.path.join(args.store, asset)
        if not os.path.exists(zst):
            try:
                urllib.request.urlretrieve(args.base_url.rstrip("/") + "/" + asset, zst + ".part")
                os.rename(zst + ".part", zst)
            except Exception as e:
                if os.path.exists(zst + ".part"):
                    os.remove(zst + ".part")
                print("miss %s: %s" % (name, e))
                continue
        with tempfile.TemporaryDirectory(dir=args.work) as tmp:
            stage, manifest = unpack(zst, tmp)
            copy_roots(stage, vals, LISTS.values())
            os.makedirs(pdir, exist_ok=True)
            for suffix, paths in manifest["lists"].items():
                with open(os.path.join(pdir, ".files-list%s.txt" % suffix), "w") as f:
                    for p in paths:
                        f.write("%s,%s\n" % (name, p))
            with open(marker, "w") as f:
                f.write(asset + "\n")
            touch_stamps(pdir, manifest["stamps"])
        print("restored %s from %s" % (name, asset))
        restored += 1
    print("restored %d packages" % restored)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["save", "restore", "keys"])
    ap.add_argument("--packages", default=os.path.join(REPO_DIR, "buildroot-config", "cached-packages"))
    ap.add_argument("--out", default=os.path.join(REPO_DIR, "pkg-cache"))
    ap.add_argument("--skip", default="")
    ap.add_argument("--base-url", default="")
    ap.add_argument("--store", default=os.path.join(os.environ.get("CACHE", REPO_DIR), "pkg-cache"))
    ap.add_argument("--work", default=os.environ.get("TMPDIR"))
    args = ap.parse_args()
    arch = os.environ.get("ARCH", "x86_64")
    build_dir = os.path.join(REPO_DIR, os.environ.get("BUILD_DIR", "buildroot-build"))
    with open(args.packages) as f:
        names = [l.split("#")[0].strip() for l in f if l.split("#")[0].strip()]
    vals = make_vars(build_dir, names)
    config = load_config(build_dir)
    if args.mode == "save":
        save(args, names, vals, config, arch)
    elif args.mode == "restore":
        restore(args, names, vals, config, arch)
    else:
        for n in names:
            if vals.get(n.upper().replace("-", "_") + "_DIR"):
                print(asset_name(n, arch, package_key(n, vals, config, arch)))


if __name__ == "__main__":
    sys.exit(main())
