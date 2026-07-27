#!/bin/bash

set -e

REPO_DIR="$(pwd)"
ATOMLOOPS="${ATOMLOOPS:-${REPO_DIR}/../AtomLoops}"
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
ATOM_LOADER_EFI="${ATOM_LOADER_EFI:-${ATOMLOOPS}/loader/bootx64.efi}"

if [ -f "${ATOM_ROOT_PUB}" ] && [ -f "${ATOM_SIGNING_KEY}" ] \
    && [ -f "${ATOM_SIGNING_CERT}" ] && [ -f "${ATOM_SIGNING_CERT_SIG}" ]; then
    # A signing chain was provided (release/production). Build a loader that trusts
    # this root.pub unless a matching loader EFI was also provided.
    if [ ! -f "${ATOM_LOADER_EFI}" ]; then
        SIGNING_WORK="$(mktemp -d)"
        cp -a "${ATOMLOOPS}/loader" "${SIGNING_WORK}/loader"
        cp "${ATOM_ROOT_PUB}" "${SIGNING_WORK}/loader/src/root.pub"
        ( cd "${SIGNING_WORK}/loader" && ZIG="${ZIG:-zig}" ./build.sh )
        ATOM_LOADER_EFI="${SIGNING_WORK}/loader/bootx64.efi"
    fi
else
    echo "[package] release signing assets incomplete; generating an ephemeral development chain"
    SIGNING_WORK="$(mktemp -d)"
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

# The initramfs finds the data/hash partitions by GPT PARTLABEL and opens the
# verity device with this root hash, so no device names are baked in. The firmware
# add-on's dm-verity hash is intentionally NOT here (see the anchor note above).
CMDLINE="console=ttyS0,115200 ro quiet loglevel=3 vt.global_cursor_default=0 udev.log_level=0 rd.systemd.show_status=0 systemd.show_status=0 rootwait sing.roothash=${ROOT_HASH} lsm=landlock,lockdown,yama,bpf lockdown=integrity module.sig_enforce=1 init_on_alloc=1 slab_nomerge page_alloc.shuffle=1 randomize_kstack_offset=1 vsyscall=none cfg80211.ieee80211_regdom=IT${EXTRA_CMDLINE:+ ${EXTRA_CMDLINE}}"

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
printf '%s' "${ATOM_VERSION:-1}" > artifacts/atomver.txt

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

# Installable GPT disk image: ESP (UKI as default boot) + labelled data/hash.
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
# (Test root key is a throwaway generated into loader/src/root.pub; the RC root key
# is Mirko's cold offline key.)
( cd "${ATOMLOOPS}" && "${ATOMLOOPS_GO:-go}" run ./cmd/atom-sign sign \
    --manifest "${REPO_DIR}/artifacts/kernelcache.efi" --priv "${ATOM_SIGNING_KEY}" )
mmd -i artifacts/esp.vfat ::EFI ::EFI/BOOT ::EFI/atom
mcopy -i artifacts/esp.vfat "${ATOM_LOADER_EFI}" ::EFI/BOOT/BOOTX64.EFI
mcopy -i artifacts/esp.vfat artifacts/kernelcache.efi          ::EFI/atom/kernelcache-active.efi
mcopy -i artifacts/esp.vfat artifacts/kernelcache.efi.sig      ::EFI/atom/kernelcache-active.efi.sig
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
cat > artifacts/deployment.json <<'DJ'
{
  "rootfs": { "current": "v1", "pending": "", "rollback": "", "boot_attempts": 0, "max_attempts": 3, "last_known_good": "v1" },
  "kernelcache": { "state": "stable", "stable_boots": 0, "stable_threshold": 3, "format": "uki" },
  "security": { "level": 2, "dm_verity": true, "secure_boot": false }
}
DJ
mcopy -i artifacts/esp.vfat artifacts/deployment.json ::EFI/atom/deployment.json

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

# Bootable hybrid ISO: efiboot.img holds the UKI for El Torito EFI boot, the ESP
# plus data and hash are appended as GPT partitions for USB boot; the initramfs
# finds data and hash by content.
ISO_ROOT="$(mktemp -d)"
mkdir -p "${ISO_ROOT}/EFI"
rm -f artifacts/efiboot.img
dd if=/dev/zero of=artifacts/efiboot.img bs=1M count=32 status=none
mkfs.fat -F 16 artifacts/efiboot.img >/dev/null
mmd -i artifacts/efiboot.img ::EFI ::EFI/BOOT
mcopy -i artifacts/efiboot.img artifacts/kernelcache.efi ::EFI/BOOT/BOOTX64.EFI
cp artifacts/efiboot.img "${ISO_ROOT}/EFI/efiboot.img"
"${HOSTBIN}/xorriso" -as mkisofs \
    -iso-level 3 -volid SINTY_OS \
    -e EFI/efiboot.img -no-emul-boot \
    -append_partition 2 0xef artifacts/esp.vfat \
    -append_partition 3 0x83 artifacts/rootfs.erofs \
    -append_partition 4 0x83 artifacts/rootfs.hash \
    -appended_part_as_gpt -isohybrid-gpt-basdat \
    -o artifacts/sinty-os.iso "${ISO_ROOT}"
rm -rf "${ISO_ROOT}" artifacts/efiboot.img

echo "[package] disk image: artifacts/sinty-os.img"
echo "[package] iso: artifacts/sinty-os.iso"
