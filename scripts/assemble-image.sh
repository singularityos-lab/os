# Installable GPT disk image: ESP (UKI as default boot) + raw root/hash.
HOSTBIN="${HOSTBIN:-${REPO_DIR}/buildroot-build/host/bin}"
HOSTSBIN="${HOSTSBIN:-${REPO_DIR}/buildroot-build/host/sbin}"
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
if [ -n "${RECOVERY_PREBUILT:-}" ]; then
    ( cd "${ATOMLOOPS}" && "${ATOMLOOPS_GO:-go}" run ./cmd/atom-sign sign \
        --manifest "${REPO_DIR}/artifacts/kernelcache-recovery.efi" --priv "${ATOM_SIGNING_KEY}" )
else
    bash scripts/build-recovery.sh
fi
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
