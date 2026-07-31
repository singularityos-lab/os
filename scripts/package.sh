#!/bin/bash

set -eo pipefail

REPO_DIR="$(pwd)"
ATOMLOOPS="${ATOMLOOPS:-${REPO_DIR}/../AtomLoops}"
SINTY_WORK_ROOT="${SINTY_WORK_ROOT:-${HOME}/sinty-work}"
mkdir -p "${SINTY_WORK_ROOT}"
if [ -z "${ATOM_VERSION:-}" ]; then
    ATOM_VERSION="$(git rev-list --count HEAD)"
fi
case "${ATOM_VERSION}" in
    *[!0-9]*|"")
        echo "package: ATOM_VERSION must be a positive integer" >&2
        exit 1
        ;;
esac
if [ "${ATOM_VERSION}" -le 0 ]; then
    echo "package: ATOM_VERSION must be a positive integer" >&2
    exit 1
fi
RELEASE_VERSION="v${ATOM_VERSION}"
export ATOM_VERSION
echo "[package] release version: ${RELEASE_VERSION}"
if [ ! -f "${ATOMLOOPS}/go.mod" ] || [ ! -f "${ATOMLOOPS}/loader/build.sh" ]; then
    echo "package: AtomLoops checkout not found at ${ATOMLOOPS}" >&2
    exit 1
fi
mkdir -p artifacts

SIGNING_WORK=""
cleanup() {
    [ -z "${SIGNING_WORK}" ] || rm -rf "${SIGNING_WORK}"
}
trap cleanup EXIT

ATOM_ROOT_PUB="${ATOM_ROOT_PUB:-${ATOMLOOPS}/loader/src/root.pub}"
ATOM_SIGNING_KEY="${ATOM_SIGNING_KEY:-${ATOMLOOPS}/signing-v1.key}"
ATOM_SIGNING_CERT="${ATOM_SIGNING_CERT:-${ATOMLOOPS}/signing-cert-v1.json}"
ATOM_SIGNING_CERT_SIG="${ATOM_SIGNING_CERT_SIG:-${ATOM_SIGNING_CERT}.sig}"
# Whether the caller pinned a loader binary. Only an explicit ATOM_LOADER_EFI is
# trusted to match the signing chain: defaulting to the AtomLoops checkout would let
# a leftover dev-root bootx64.efi sitting there silently replace the release loader,
# and the image then halts at "signature INVALID" because that loader cannot verify
# a production-signed UKI. Unset means always rebuild against ATOM_ROOT_PUB.
LOADER_PINNED=1
[ -n "${ATOM_LOADER_EFI:-}" ] || LOADER_PINNED=0
ATOM_LOADER_EFI="${ATOM_LOADER_EFI:-${ATOMLOOPS}/loader/bootx64.efi}"

if [ -f "${ATOM_ROOT_PUB}" ] && [ -f "${ATOM_SIGNING_KEY}" ] \
    && [ -f "${ATOM_SIGNING_CERT}" ] && [ -f "${ATOM_SIGNING_CERT_SIG}" ]; then
    # A signing chain was provided (release/production). Build a loader that trusts
    # this root.pub unless the caller pinned a matching loader EFI.
    if [ "${LOADER_PINNED}" = 0 ] || [ ! -f "${ATOM_LOADER_EFI}" ]; then
        SIGNING_WORK="$(mktemp -d "${SINTY_WORK_ROOT}/package-signing.XXXXXX")"
        cp -a "${ATOMLOOPS}/loader" "${SIGNING_WORK}/loader"
        cp "${ATOM_ROOT_PUB}" "${SIGNING_WORK}/loader/src/root.pub"
        ( cd "${SIGNING_WORK}/loader" && ZIG="${ZIG:-zig}" ./build.sh )
        ATOM_LOADER_EFI="${SIGNING_WORK}/loader/bootx64.efi"
    fi
else
    echo "[package] release signing assets incomplete; generating an ephemeral development chain"
    SIGNING_WORK="$(mktemp -d "${SINTY_WORK_ROOT}/package-signing.XXXXXX")"
    ROOT_KEY="${SIGNING_WORK}/root.key"
    ATOM_ROOT_PUB="${SIGNING_WORK}/root.pub"
    ATOM_SIGNING_KEY="${SIGNING_WORK}/signing-v1.key"
    ATOM_SIGNING_CERT="${SIGNING_WORK}/signing-cert-v1.json"
    ATOM_SIGNING_CERT_SIG="${ATOM_SIGNING_CERT}.sig"
    (
        cd "${ATOMLOOPS}"
        "${ATOMLOOPS_GO:-go}" run ./cmd/atom-sign keygen \
            --priv "${ROOT_KEY}" --pub "${ATOM_ROOT_PUB}"
        "${ATOMLOOPS_GO:-go}" run ./cmd/atom-sign issue-cert \
            --root "${ROOT_KEY}" --version 1 \
            --cert "${ATOM_SIGNING_CERT}" --signing-key "${ATOM_SIGNING_KEY}"
    )
    cp -a "${ATOMLOOPS}/loader" "${SIGNING_WORK}/loader"
    cp "${ATOM_ROOT_PUB}" "${SIGNING_WORK}/loader/src/root.pub"
    ( cd "${SIGNING_WORK}/loader" && ZIG="${ZIG:-zig}" ./build.sh )
    ATOM_LOADER_EFI="${SIGNING_WORK}/loader/bootx64.efi"
fi
export ATOM_ROOT_PUB ATOM_SIGNING_KEY ATOM_SIGNING_CERT ATOM_SIGNING_CERT_SIG

# The loader is the root of the whole verified chain, and shipping one built against
# the wrong root.pub produces an image that halts at "signature INVALID" only once it
# is booted on real hardware. Assert the trust root is actually inside the binary.
# The key is 32 raw bytes with embedded NULs, so this is a byte search, not a grep.
python3 - "${ATOM_ROOT_PUB}" "${ATOM_LOADER_EFI}" <<'PY' || exit 1
import sys
key = open(sys.argv[1], 'rb').read()
if key not in open(sys.argv[2], 'rb').read():
    print(f"package: {sys.argv[2]} does not embed {sys.argv[1]} -- refusing to ship", file=sys.stderr)
    sys.exit(1)
PY
echo "[package] loader trust root verified: $(sha256sum "${ATOM_ROOT_PUB}" | cut -c1-16)"

# RootFS
ROOTFS_TAR=artifacts/rootfs.tar
bzcat buildroot-build/images/rootfs.tar.bz2 > "$ROOTFS_TAR"
# mkfs.erofs does not truncate an existing output file: a stale rootfs.erofs from a
# previous build would survive and get shipped, silently embedding an old rootfs (e.g.
# missing a package added since). Remove it first so the image always reflects the
# current tarball.
rm -f artifacts/rootfs.erofs
mkfs.erofs --tar=f -z lz4hc,9 -E ztailpacking artifacts/rootfs.erofs "$ROOTFS_TAR"

# Verity
# Same class as the erofs above: veritysetup format does not truncate a pre-existing
# hash file, so a larger stale rootfs.hash would keep a dead tail past the hash tree.
rm -f artifacts/rootfs.hash
veritysetup format artifacts/rootfs.erofs artifacts/rootfs.hash | tee artifacts/verity-output.txt
ROOT_HASH=$(awk '/Root hash:/{print $3}' artifacts/verity-output.txt)
DATA_BLOCKS=$(awk '/Data blocks:/{print $3}' artifacts/verity-output.txt)
SALT=$(awk '/Salt:/{print $2}' artifacts/verity-output.txt)
DM_LEN=$((DATA_BLOCKS * 8))

if [ -n "$GITHUB_ENV" ]; then
    echo "ROOT_HASH=${ROOT_HASH}" >> "$GITHUB_ENV"
fi

# Firmware add-on trust anchor: build the statically linked fw-verify and bake it plus
# the release root public key into the (signed) initramfs. The firmware dm-verity root
# hash is NOT carried in the UKI cmdline anymore -- a signed cmdline is fixed at build
# time, so an OTA could never update it. Instead the initramfs re-verifies the release-
# signed anchor beside the image (root pubkey -> signing cert -> manifest) and opens
# dm-verity with the hash it extracts. Absent verifier/anchor -> base survival firmware.
# FW_ROOT_PUB may be pre-set (e.g. a test trust root for a VM trial); default to the
# release root the loader verifies the UKI with.
: "${FW_ROOT_PUB:=${ATOM_ROOT_PUB}}"
if [ -f "${FW_ROOT_PUB}" ]; then
    # FW_VERIFY_BIN may be pre-set to a known-good build (e.g. when AtomLoops HEAD is
    # mid-refactor); otherwise build it from source.
    if { [ -z "${FW_VERIFY_BIN}" ] || [ ! -x "${FW_VERIFY_BIN}" ]; } \
        && [ -d "${ATOMLOOPS}/cmd/fw-verify" ]; then
        ( cd "${ATOMLOOPS}" && CGO_ENABLED=0 "${ATOMLOOPS_GO:-go}" build -ldflags '-s -w' \
            -o "${REPO_DIR}/artifacts/fw-verify" ./cmd/fw-verify )
        FW_VERIFY_BIN="${REPO_DIR}/artifacts/fw-verify"
    fi
    if [ -n "${FW_VERIFY_BIN}" ] && [ -x "${FW_VERIFY_BIN}" ]; then
        export FW_VERIFY_BIN FW_ROOT_PUB
    fi
fi

# Initramfs: the dm-verity aware init that waits for the kernel-created
# verity device, mounts the verified erofs read-only and overlays a tmpfs.
bash scripts/build-initramfs.sh buildroot-build/target artifacts/initrd.cpio.xz

# The initramfs finds the root/hash partitions by content and opens the
# verity device with this root hash, so no device names are baked in. The firmware
# add-on's dm-verity hash is intentionally NOT here (see the anchor note above).
CMDLINE="console=tty0 console=ttyS0,115200 ro quiet loglevel=0 vt.global_cursor_default=0 udev.log_level=0 rd.systemd.show_status=0 systemd.show_status=0 rootwait sing.roothash=${ROOT_HASH} atom.version=${RELEASE_VERSION} lsm=landlock,lockdown,yama,bpf lockdown=integrity module.sig_enforce=1 init_on_alloc=1 slab_nomerge page_alloc.shuffle=1 randomize_kstack_offset=1 vsyscall=none cfg80211.ieee80211_regdom=IT${EXTRA_CMDLINE:+ ${EXTRA_CMDLINE}}"

# UKI: place the added sections above the stub's image so they do not fall
# below the PE image base.
KERNEL="buildroot-build/images/bzImage"
STUB="/usr/lib/systemd/boot/efi/linuxx64.efi.stub"
BASE=$((16#$(objdump -p "$STUB" | awk '/ImageBase/{print $2}')))
vma() { printf "0x%x" $((BASE + $1)); }

OSREL=""
[ -f buildroot-build/target/usr/lib/os-release ] && OSREL="--add-section .osrel=buildroot-build/target/usr/lib/os-release --change-section-vma .osrel=$(vma 0x100000)"

printf '%s' "$CMDLINE" > artifacts/cmdline.txt
# .atomver: the kernelcache version baked into the SIGNED UKI, read by the loader to
# enforce anti-rollback. The daemon's NV counter (index 0x0150A701) is the floor.
printf '%s' "${ATOM_VERSION}" > artifacts/atomver.txt

objcopy \
    $OSREL \
    --add-section .cmdline=artifacts/cmdline.txt \
    --change-section-vma .cmdline=$(vma 0x110000) \
    --add-section .atomver=artifacts/atomver.txt \
    --change-section-vma .atomver=$(vma 0x108000) \
    --add-section .linux="$KERNEL" \
    --change-section-vma .linux=$(vma 0x200000) \
    --add-section .initrd=artifacts/initrd.cpio.xz \
    --change-section-vma .initrd=$(vma 0x2000000) \
    "$STUB" artifacts/kernelcache.efi

echo "[package] UKI: artifacts/kernelcache.efi"
echo "[package] root hash: ${ROOT_HASH}"

# Live and installed kernelcaches select different root layouts. The signed flag keeps
# a slow removable root from falling through to an installed slot with the same hash.
LIVE_CMDLINE="${CMDLINE} sing.live=1"
printf '%s' "$LIVE_CMDLINE" > artifacts/cmdline-live.txt
objcopy \
    $OSREL \
    --add-section .cmdline=artifacts/cmdline-live.txt \
    --change-section-vma .cmdline=$(vma 0x110000) \
    --add-section .atomver=artifacts/atomver.txt \
    --change-section-vma .atomver=$(vma 0x108000) \
    --add-section .linux="$KERNEL" \
    --change-section-vma .linux=$(vma 0x200000) \
    --add-section .initrd=artifacts/initrd.cpio.xz \
    --change-section-vma .initrd=$(vma 0x2000000) \
    "$STUB" artifacts/kernelcache-live.efi

# Portable mode uses the live raw root and may attach installed writable data.
PORTABLE_CMDLINE="${LIVE_CMDLINE} sing.portable=1"
printf '%s' "$PORTABLE_CMDLINE" > artifacts/cmdline-portable.txt
objcopy \
    $OSREL \
    --add-section .cmdline=artifacts/cmdline-portable.txt \
    --change-section-vma .cmdline=$(vma 0x110000) \
    --add-section .atomver=artifacts/atomver.txt \
    --change-section-vma .atomver=$(vma 0x108000) \
    --add-section .linux="$KERNEL" \
    --change-section-vma .linux=$(vma 0x200000) \
    --add-section .initrd=artifacts/initrd.cpio.xz \
    --change-section-vma .initrd=$(vma 0x2000000) \
    "$STUB" artifacts/kernelcache-portable.efi

# Installable GPT disk image: ESP (UKI as default boot) + raw root/hash.
HOSTBIN="${REPO_DIR}/buildroot-build/host/bin"
HOSTSBIN="${REPO_DIR}/buildroot-build/host/sbin"
export PATH="${HOSTBIN}:${HOSTSBIN}:${PATH}"
export MTOOLS_SKIP_CHECK=1

rm -f artifacts/esp.vfat
# 256M: must hold the loader + active UKI + its sig + certs AND the Tier-2 recovery UKI
# (~65M) + its sig. 64M overflowed once the recovery slot was added (mcopy: Disk full).
dd if=/dev/zero of=artifacts/esp.vfat bs=1M count=256 status=none
mkfs.fat -F 32 -n SINGEFI artifacts/esp.vfat >/dev/null
# Atom Loops loader is BOOTX64.EFI; it verifies + chainloads the signed UKI slot.
# Development builds use a throwaway root key; release builds use the offline root.
( cd "${ATOMLOOPS}" && "${ATOMLOOPS_GO:-go}" run ./cmd/atom-sign sign \
    --manifest "${REPO_DIR}/artifacts/kernelcache.efi" --priv "${ATOM_SIGNING_KEY}" )
( cd "${ATOMLOOPS}" && "${ATOMLOOPS_GO:-go}" run ./cmd/atom-sign sign \
    --manifest "${REPO_DIR}/artifacts/kernelcache-live.efi" --priv "${ATOM_SIGNING_KEY}" )
( cd "${ATOMLOOPS}" && "${ATOMLOOPS_GO:-go}" run ./cmd/atom-sign sign \
    --manifest "${REPO_DIR}/artifacts/kernelcache-portable.efi" --priv "${ATOM_SIGNING_KEY}" )
mmd -i artifacts/esp.vfat ::EFI ::EFI/BOOT ::EFI/atom
mcopy -i artifacts/esp.vfat "${ATOM_LOADER_EFI}" ::EFI/BOOT/BOOTX64.EFI
mcopy -i artifacts/esp.vfat artifacts/kernelcache.efi          ::EFI/atom/kernelcache-active.efi
mcopy -i artifacts/esp.vfat artifacts/kernelcache.efi.sig      ::EFI/atom/kernelcache-active.efi.sig
mcopy -i artifacts/esp.vfat artifacts/kernelcache.efi          ::EFI/atom/kernelcache-install.efi
mcopy -i artifacts/esp.vfat artifacts/kernelcache.efi.sig      ::EFI/atom/kernelcache-install.efi.sig
mcopy -i artifacts/esp.vfat "${ATOM_SIGNING_CERT}"     ::EFI/atom/signing-cert.json
mcopy -i artifacts/esp.vfat "${ATOM_SIGNING_CERT_SIG}" ::EFI/atom/signing-cert.json.sig
# recovery slot (Tier-2): a REAL standalone recovery image -- busybox + wpa_supplicant +
# udhcpc + the atom-recovery menu (wifi, verified reinstall, repair), NOT a copy of active.
# build-recovery.sh builds + signs artifacts/kernelcache-recovery.efi (self-contained UKI,
# so the loader's Ed25519 over the whole image already verifies it). Proven to boot to the
# recovery menu in QEMU. The loader selects+chainloads it on boot-state target=recovery.
bash scripts/build-recovery.sh
mcopy -i artifacts/esp.vfat artifacts/kernelcache-recovery.efi     ::EFI/atom/kernelcache-recovery.efi
mcopy -i artifacts/esp.vfat artifacts/kernelcache-recovery.efi.sig ::EFI/atom/kernelcache-recovery.efi.sig
printf 'target=active\ntrial=0\nattempts=0\n' > artifacts/boot-state
mcopy -i artifacts/esp.vfat artifacts/boot-state ::EFI/atom/boot-state
cat > artifacts/deployment.json <<DJ
{
  "rootfs": { "current": "${RELEASE_VERSION}", "pending": "", "rollback": "", "boot_attempts": 0, "max_attempts": 3, "last_known_good": "${RELEASE_VERSION}" },
  "kernelcache": { "state": "stable", "stable_boots": 0, "stable_threshold": 3, "format": "uki" },
  "security": { "level": 2, "dm_verity": true, "secure_boot": false }
}
DJ
mcopy -i artifacts/esp.vfat artifacts/deployment.json ::EFI/atom/deployment.json

# The live and portable ESPs differ only in their signed active UKI. The installer
# promotes kernelcache-install.efi after copying the source ESP to the target disk.
cp artifacts/esp.vfat artifacts/esp-live.vfat
mcopy -o -i artifacts/esp-live.vfat artifacts/kernelcache-live.efi \
    ::EFI/atom/kernelcache-active.efi
mcopy -o -i artifacts/esp-live.vfat artifacts/kernelcache-live.efi.sig \
    ::EFI/atom/kernelcache-active.efi.sig

cp artifacts/esp.vfat artifacts/esp-portable.vfat
mcopy -o -i artifacts/esp-portable.vfat artifacts/kernelcache-portable.efi \
    ::EFI/atom/kernelcache-active.efi
mcopy -o -i artifacts/esp-portable.vfat artifacts/kernelcache-portable.efi.sig \
    ::EFI/atom/kernelcache-active.efi.sig

# Removable log-collection partition (SINTYLOGS): singularity-logcollect mirrors the
# boot journal/dmesg/session logs here so they can be read back off-device.
rm -f artifacts/sintylogs.ext4
dd if=/dev/zero of=artifacts/sintylogs.ext4 bs=1M count=256 status=none
/usr/sbin/mkfs.ext4 -q -L SINTYLOGS -F artifacts/sintylogs.ext4

rm -rf genimage-tmp
"${HOSTBIN}/genimage" \
    --config scripts/genimage.cfg \
    --inputpath artifacts \
    --outputpath artifacts \
    --tmppath genimage-tmp

rm -rf genimage-portable-tmp
"${HOSTBIN}/genimage" \
    --config scripts/genimage-portable.cfg \
    --inputpath artifacts \
    --outputpath artifacts \
    --tmppath genimage-portable-tmp

# Bootable optical ISO: El Torito boots the full live ESP, while ISO9660 carries the
# root and hash as files for the initramfs to attach and verify through loop devices.
ISO_ROOT="$(mktemp -d "${SINTY_WORK_ROOT}/package-iso.XXXXXX")"
mkdir -p "${ISO_ROOT}/EFI" "${ISO_ROOT}/live"
cp artifacts/esp-live.vfat "${ISO_ROOT}/EFI/efiboot.img"
cp artifacts/rootfs.erofs "${ISO_ROOT}/live/rootfs.erofs"
cp artifacts/rootfs.hash "${ISO_ROOT}/live/rootfs.hash"
"${HOSTBIN}/xorriso" -as mkisofs \
    -iso-level 3 -volid SINTY_OS \
    -e EFI/efiboot.img -no-emul-boot \
    -o artifacts/sinty-os.iso "${ISO_ROOT}"
rm -rf "${ISO_ROOT}"

echo "[package] disk image: artifacts/sinty-os.img"
echo "[package] portable image: artifacts/sinty-os-portable.img"
echo "[package] iso: artifacts/sinty-os.iso"
