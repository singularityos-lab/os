#!/bin/bash
# build-recovery.sh -- Tier-2 recovery image builder.
#
# Produces a REAL signed recovery UKI (kernelcache-recovery.efi) instead of the current
# `cp kernelcache.efi kernelcache-recovery.efi` copy (package.sh:80). The recovery env is
# self-contained in the UKI's embedded initramfs (so the loader's Ed25519 over the whole
# UKI already verifies it -- no separate dm-verity needed): busybox + wpa_supplicant +
# udhcpc + veritysetup + the wifi firmware + the static atom-recovery binary, which brings
# up wifi directly and re-downloads/verifies/reinstalls a signed image (macOS-Recovery style).
#
# usage: build-recovery.sh   (run from the singularity-os repo root, after a normal build)
set -eu
REPO_DIR="$(pwd)"
TARGET_DIR="${TARGET_DIR:-buildroot-build/target}"
KERNEL="${KERNEL:-buildroot-build/images/bzImage}"
ATOMLOOPS="${ATOMLOOPS:-${REPO_DIR}/../AtomLoops}"
SINTY_RECOVERY="${SINTY_RECOVERY:-${REPO_DIR}/../sinty-recovery}"
ATOM_ROOT_PUB="${ATOM_ROOT_PUB:-${ATOMLOOPS}/loader/src/root.pub}"
ATOM_SIGNING_KEY="${ATOM_SIGNING_KEY:-${ATOMLOOPS}/signing-v1.key}"
if [ ! -f "$SINTY_RECOVERY/go.mod" ]; then
	echo "build-recovery: sinty-recovery checkout not found at $SINTY_RECOVERY" >&2
	exit 1
fi
STUB="${STUB:-$(ls /usr/lib/systemd/boot/efi/linuxx64.efi.stub 2>/dev/null || echo "$TARGET_DIR/usr/lib/systemd/boot/efi/linuxx64.efi.stub")}"
OUT="artifacts/kernelcache-recovery.efi"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK"/{bin,sbin,lib,lib64,usr/bin,usr/sbin,proc,sys,dev,tmp,newroot,run,lib/firmware}

copy_bin() { # $1 name  $2 destdir(sbin/bin)
	for d in sbin usr/sbin bin usr/bin; do
		[ -e "$TARGET_DIR/$d/$1" ] && { cp -aL "$TARGET_DIR/$d/$1" "$WORK/$2/$1"; return 0; }
	done
	echo "build-recovery: $1 not found in target" >&2; return 1
}
# recursively copy a binary's NEEDED shared libs out of the target (transitive closure)
copy_libs() {
	local bin="$1" so d
	for so in $("${CROSS_READELF:-readelf}" -d "$bin" 2>/dev/null | sed -n 's/.*NEEDED.*\[\(.*\)\]/\1/p'); do
		[ -e "$WORK/lib/$so" ] && continue # already staged -> stop the recursion
		for d in lib usr/lib; do
			if [ -e "$TARGET_DIR/$d/$so" ]; then
				cp -aL "$TARGET_DIR/$d/$so" "$WORK/lib/$so"
				copy_libs "$WORK/lib/$so" # recurse into the lib's own deps
				break
			fi
		done
	done
}

echo "[recovery] staging busybox + wifi + verity tools"
copy_bin busybox bin
for t in sh mount umount ip ifconfig switch_root modprobe mkdir cat; do
	ln -sf busybox "$WORK/bin/$t"
done
copy_bin wpa_supplicant sbin || echo "  (wpa_supplicant missing -- add BR2_PACKAGE_WPA_SUPPLICANT)"
copy_bin udhcpc sbin || ln -sf ../bin/busybox "$WORK/sbin/udhcpc"
copy_bin veritysetup sbin || true
for b in "$WORK"/bin/busybox "$WORK"/sbin/*; do [ -f "$b" ] && copy_libs "$b"; done
# the dynamic loader + /lib64 -> /lib (busybox's ELF interpreter is /lib64/ld-linux-x86-64.so.2)
cp -aL "$TARGET_DIR/lib/ld-linux-x86-64.so.2" "$WORK/lib/" 2>/dev/null || true
rm -rf "$WORK/lib64"; ln -sf lib "$WORK/lib64"

echo "[recovery] building the static atom-recovery binary"
# GOPROXY is set explicitly rather than inherited: this build runs after buildroot, whose
# own Go packages leave a module environment behind, and a GOPROXY that survives from there
# resolves to an empty proxy list here ("GOPROXY list is not the empty string, but contains
# no entries"). The dependencies are public modules, so the default proxy fetches them; an
# already-populated module cache still short-circuits the download.
( cd "$SINTY_RECOVERY" && CGO_ENABLED=0 GOFLAGS= \
	GOPROXY="${RECOVERY_GOPROXY:-https://proxy.golang.org,direct}" \
	"${RECOVERY_GO:-go}" build -ldflags='-s -w' \
	-o "$WORK/sbin/atom-recovery" ./cmd/atom-recovery )
# the embedded ROOT trust anchor: atom-recovery verifies every re-downloaded image against it
# (independent of the possibly-dead main system). Same ROOT key the loader is built with.
mkdir -p "$WORK/etc/atom"
cp "$ATOM_ROOT_PUB" "$WORK/etc/atom/root.pub"

echo "[recovery] wifi firmware ONLY (no audio/gpu -- recovery just needs to get online)"
mkdir -p "$WORK/lib/firmware/mediatek"
cp -a "$TARGET_DIR"/lib/firmware/iwlwifi-*.ucode "$WORK/lib/firmware/" 2>/dev/null || true
cp -a "$TARGET_DIR"/lib/firmware/regulatory.db* "$WORK/lib/firmware/" 2>/dev/null || true
cp -a "$TARGET_DIR"/lib/firmware/mediatek/mt76* "$TARGET_DIR"/lib/firmware/mediatek/mt79* \
      "$TARGET_DIR"/lib/firmware/mediatek/WIFI_* "$WORK/lib/firmware/mediatek/" 2>/dev/null || true
for sub in rtw88 rtw89 ath10k ath11k ath12k brcm cypress; do
	cp -a "$TARGET_DIR"/lib/firmware/$sub "$WORK/lib/firmware/" 2>/dev/null || true
done

echo "[recovery] /init -> launch atom-recovery"
cat > "$WORK/init" <<'INIT'
#!/bin/sh
mount -t proc proc /proc 2>/dev/null
mount -t sysfs sys /sys 2>/dev/null
mount -t devtmpfs dev /dev 2>/dev/null
mount -t tmpfs tmp /run 2>/dev/null
echo "[recovery] Singularity Recovery"
for m in cfg80211 mac80211 iwlwifi mt7921e ath11k_pci; do modprobe "$m" 2>/dev/null; done
/sbin/atom-recovery || { echo "[recovery] atom-recovery exited; rescue shell"; exec /bin/sh; }
exec /bin/sh
INIT
chmod 0755 "$WORK/init"

echo "[recovery] cpio.xz"
( cd "$WORK" && find . | cpio -o -H newc 2>/dev/null | xz -9 --check=crc32 ) > artifacts/recovery-initrd.cpio.xz

echo "[recovery] UKI (kernel + recovery initramfs + recovery cmdline)"
BASE=$((16#$(objdump -p "$STUB" | awk '/ImageBase/{print $2}')))
vma() { printf '0x%x' $((BASE + $1)); } # place sections ABOVE the stub's ImageBase (like package.sh)
printf 'console=ttyS0 console=tty0 atom.recovery=1 ro\n' > artifacts/recovery-cmdline.txt
objcopy \
	--add-section .cmdline=artifacts/recovery-cmdline.txt --change-section-vma .cmdline=$(vma 0x110000) \
	--add-section .linux="$KERNEL"                        --change-section-vma .linux=$(vma 0x200000) \
	--add-section .initrd=artifacts/recovery-initrd.cpio.xz --change-section-vma .initrd=$(vma 0x2000000) \
	"$STUB" "$OUT"
echo "[recovery] signing"
( cd "$ATOMLOOPS" && "${ATOMLOOPS_GO:-go}" run ./cmd/atom-sign sign --manifest "$REPO_DIR/$OUT" --priv "$ATOM_SIGNING_KEY" )
echo "[recovery] DONE: $OUT ($(du -h "$OUT" | cut -f1)) + $OUT.sig -- wire into package.sh (replace the cp)"
