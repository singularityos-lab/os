#!/bin/bash
# build-recovery.sh -- Tier-2 recovery image builder.
#
# Produces a REAL signed recovery UKI (kernelcache-recovery.efi) instead of the current
# `cp kernelcache.efi kernelcache-recovery.efi` copy (package.sh:80). The recovery env is
# self-contained in the UKI's embedded initramfs (so the loader's Ed25519 over the whole
# UKI already verifies it -- no separate dm-verity needed): busybox + wpa_supplicant +
# udhcpc + veritysetup + the wifi firmware + the static atom-recovery binary, which brings
# up Wi-Fi directly and re-downloads, verifies, and reinstalls a signed image.
#
# usage: build-recovery.sh   (run from the singularity-os repo root, after a normal build)
set -eu
REPO_DIR="$(pwd)"
SINTY_WORK_ROOT="${SINTY_WORK_ROOT:-${HOME}/sinty-work}"
mkdir -p "$SINTY_WORK_ROOT"
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
WORK="$(mktemp -d "${SINTY_WORK_ROOT}/recovery.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK"/{bin,sbin,lib,lib64,usr/bin,usr/sbin,usr/lib,usr/libexec,usr/share,proc,sys,dev,tmp,newroot,run,boot/efi,var,etc,lib/firmware}

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
for t in sh mount umount ip ifconfig switch_root modprobe mkdir cat grep sed tr readlink basename dirname sleep sync kill reboot stty; do
	ln -sf busybox "$WORK/bin/$t"
done
copy_bin blkid usr/bin
copy_bin wpa_supplicant sbin || echo "  (wpa_supplicant missing -- add BR2_PACKAGE_WPA_SUPPLICANT)"
copy_bin udhcpc sbin || ln -sf ../bin/busybox "$WORK/sbin/udhcpc"
copy_bin veritysetup sbin || true
for b in "$WORK"/bin/busybox "$WORK"/sbin/*; do [ -f "$b" ] && copy_libs "$b"; done
copy_libs "$WORK/usr/bin/blkid"
# the dynamic loader + /lib64 -> /lib (busybox's ELF interpreter is /lib64/ld-linux-x86-64.so.2)
cp -aL "$TARGET_DIR/lib/ld-linux-x86-64.so.2" "$WORK/lib/" 2>/dev/null || true
rm -rf "$WORK/lib64"; ln -sf lib "$WORK/lib64"

echo "[recovery] staging storage, TPM and graphics runtime"
if [ -d "$TARGET_DIR/lib/modules" ]; then
	cp -a "$TARGET_DIR/lib/modules" "$WORK/lib/"
else
	echo "build-recovery: kernel modules missing from target" >&2
	exit 1
fi
copy_bin sintykey usr/bin
if [ ! -x "$TARGET_DIR/usr/libexec/sintykey-tpm" ]; then
	echo "build-recovery: sintykey-tpm not found in target" >&2
	exit 1
fi
cp -aL "$TARGET_DIR/usr/libexec/sintykey-tpm" "$WORK/usr/libexec/sintykey-tpm"
copy_libs "$WORK/usr/bin/sintykey"
copy_libs "$WORK/usr/libexec/sintykey-tpm"
if [ ! -e "$TARGET_DIR/usr/lib/libtss2-tcti-device.so.0" ]; then
	echo "build-recovery: TPM device TCTI not found in target" >&2
	exit 1
fi
cp -aL "$TARGET_DIR/usr/lib/libtss2-tcti-device.so.0" "$WORK/lib/libtss2-tcti-device.so.0"
if copy_bin sinty-recovery-ui usr/bin; then
	copy_libs "$WORK/usr/bin/sinty-recovery-ui"
	cp -a "$TARGET_DIR/etc/fonts" "$WORK/etc/" 2>/dev/null || true
	mkdir -p "$WORK/usr/share/fonts"
	cp -a "$TARGET_DIR/usr/share/fonts/." "$WORK/usr/share/fonts/" 2>/dev/null || true
	cp -a "$TARGET_DIR/usr/share/fontconfig" "$WORK/usr/share/" 2>/dev/null || true
	cp -a "$TARGET_DIR/usr/share/singularity" "$WORK/usr/share/" 2>/dev/null || true
	cp -a "$TARGET_DIR/usr/share/X11" "$WORK/usr/share/" 2>/dev/null || true
	cp -a "$TARGET_DIR/usr/lib/gdk-pixbuf-2.0" "$WORK/usr/lib/" 2>/dev/null || true
else
	echo "  (sinty-recovery-ui missing, text recovery remains available)"
fi

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

echo "[recovery] /init -> locate installed volumes and launch recovery"
cat > "$WORK/init" <<'INIT'
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc proc /proc 2>/dev/null
mount -t sysfs sys /sys 2>/dev/null
mount -t devtmpfs dev /dev 2>/dev/null
mount -t tmpfs tmp /run 2>/dev/null
mkdir -p /run/probe /run/data-probe /var /boot /boot/efi
for m in f2fs vfat tpm tpm_tis tpm_crb simpledrm cfg80211 mac80211 iwlwifi mt7921e ath11k_pci; do
	modprobe "$m" 2>/dev/null
done

recovery_fail() {
	echo "$1"
	sleep 10
	/bin/reboot -f
	while :; do sleep 60; done
}

parent_disk() {
	_path=$(readlink -f "/sys/class/block/$1") || return 1
	basename "$(dirname "$_path")"
}

valid_install_id() {
	[ "${#1}" -eq 32 ] || return 1
	case "$1" in
		*[!0-9a-f]*) return 1 ;;
	esac
}

find_pairs() {
	_want_armed="$1"
	_pair_count=0
	_pair_esp=
	_pair_data=
	for _esp_sys in /sys/class/block/*; do
		[ -f "$_esp_sys/partition" ] || continue
		_esp=$(basename "$_esp_sys")
		[ "$(blkid -s TYPE -o value "/dev/$_esp" 2>/dev/null)" = "vfat" ] || continue
		mount -t vfat -o ro "/dev/$_esp" /run/probe 2>/dev/null || continue
		_atom=/run/probe/EFI/atom
		_valid=0
		[ -f "$_atom/kernelcache-recovery.efi" ] && _valid=1
		_esp_id=$(tr -d '\r\n' < "$_atom/state/install-id" 2>/dev/null || true)
		valid_install_id "$_esp_id" || _valid=0
		_armed=0
		if grep -q '"armed"[[:space:]]*:[[:space:]]*true' "$_atom/state/unlock-armed" 2>/dev/null \
			&& grep -Eq '"owner_uid"[[:space:]]*:[[:space:]]*[1-9][0-9][0-9][0-9]+' "$_atom/state/unlock-armed" 2>/dev/null; then
			_armed=1
		fi
		if [ "$_valid" = 1 ] && { [ "$_want_armed" = 0 ] || [ "$_armed" = 1 ]; }; then
			_parent=$(parent_disk "$_esp")
			for _data_sys in /sys/class/block/*; do
				[ -f "$_data_sys/partition" ] || continue
				_data=$(basename "$_data_sys")
				[ "$_data" != "$_esp" ] || continue
				[ "$(parent_disk "$_data")" = "$_parent" ] || continue
				[ "$(blkid -s LABEL -o value "/dev/$_data" 2>/dev/null)" = "atom-data" ] || continue
				[ "$(blkid -s TYPE -o value "/dev/$_data" 2>/dev/null)" = "f2fs" ] || continue
				mount -t f2fs -o ro "/dev/$_data" /run/data-probe 2>/dev/null || continue
				_data_id=$(tr -d '\r\n' < /run/data-probe/.atom-install-id 2>/dev/null || true)
				if [ -f /run/data-probe/.atom-var ] \
					&& valid_install_id "$_data_id" \
					&& [ "$_data_id" = "$_esp_id" ] \
					&& [ -f /run/data-probe/boot/rootfs/deployment.json ] \
					&& [ -f /run/data-probe/boot/rootfs/rootfs-active.erofs ] \
					&& [ -f /run/data-probe/boot/rootfs/rootfs-active.hash ]; then
					_pair_count=$((_pair_count + 1))
					_pair_esp="/dev/$_esp"
					_pair_data="/dev/$_data"
				fi
				umount /run/data-probe 2>/dev/null
			done
		fi
		umount /run/probe 2>/dev/null
	done
	[ "$_pair_count" -eq 1 ] || {
		[ "$_pair_count" -eq 0 ] && return 1
		return 2
	}
	ESP_DEV=$_pair_esp
	DATA_DEV=$_pair_data
	return 0
}

ESP_DEV=
DATA_DEV=
if find_pairs 1; then
	:
else
	_pair_status=$?
	[ "$_pair_status" -ne 2 ] || recovery_fail "Sinty Recovery found multiple armed installed systems."
	if find_pairs 0; then
		:
	else
		_pair_status=$?
		[ "$_pair_status" -ne 2 ] || recovery_fail "Sinty Recovery found multiple installed systems."
		recovery_fail "Sinty Recovery could not find a valid installed system."
	fi
fi

mount "$DATA_DEV" /var 2>/dev/null || {
	recovery_fail "Sinty Recovery could not mount atom-data."
}
mount --bind /var/boot /boot 2>/dev/null || {
	recovery_fail "Sinty Recovery could not expose the rootfs slots."
}
mkdir -p /boot/efi
mount "$ESP_DEV" /boot/efi 2>/dev/null || {
	recovery_fail "Sinty Recovery could not mount the system partition."
}

RECOVERY_ARGS="--wal /boot/rootfs/deployment.json --data-dir /var --rootfs-dir /boot/rootfs --esp-dir /boot/efi/EFI/atom --sintykey /usr/bin/sintykey"
/sbin/atom-recovery --mode serve $RECOVERY_ARGS &
AGENT_PID=$!
_wait=0
while [ ! -S /run/atom-recovery.sock ] && [ "$_wait" -lt 50 ]; do
	sleep 0.1
	_wait=$((_wait + 1))
done

if [ -x /usr/bin/sinty-recovery-ui ] && [ -S /run/atom-recovery.sock ]; then
	/usr/bin/sinty-recovery-ui && {
		kill "$AGENT_PID" 2>/dev/null
		wait "$AGENT_PID" 2>/dev/null
		exec /bin/reboot -f
	}
fi

kill "$AGENT_PID" 2>/dev/null
wait "$AGENT_PID" 2>/dev/null
echo "Graphical recovery unavailable. Starting text recovery."
/sbin/atom-recovery --mode tty $RECOVERY_ARGS || {
	recovery_fail "Sinty Recovery stopped."
}
exec /bin/reboot -f
INIT
chmod 0755 "$WORK/init"

echo "[recovery] cpio.xz"
( cd "$WORK" && find . | cpio -o -H newc 2>/dev/null | xz -9 --check=crc32 ) > artifacts/recovery-initrd.cpio.xz

echo "[recovery] UKI (kernel + recovery initramfs + recovery cmdline)"
BASE=$((16#$(objdump -p "$STUB" | awk '/ImageBase/{print $2}')))
vma() { printf '0x%x' $((BASE + $1)); } # place sections ABOVE the stub's ImageBase (like package.sh)
printf 'console=ttyS0 console=tty0 quiet loglevel=3 vt.global_cursor_default=0 atom.recovery=1 ro\n' > artifacts/recovery-cmdline.txt
objcopy \
	--add-section .cmdline=artifacts/recovery-cmdline.txt --change-section-vma .cmdline=$(vma 0x110000) \
	--add-section .linux="$KERNEL"                        --change-section-vma .linux=$(vma 0x200000) \
	--add-section .initrd=artifacts/recovery-initrd.cpio.xz --change-section-vma .initrd=$(vma 0x2000000) \
	"$STUB" "$OUT"
echo "[recovery] signing"
( cd "$ATOMLOOPS" && "${ATOMLOOPS_GO:-go}" run ./cmd/atom-sign sign --manifest "$REPO_DIR/$OUT" --priv "$ATOM_SIGNING_KEY" )
echo "[recovery] DONE: $OUT ($(du -h "$OUT" | cut -f1)) + $OUT.sig -- wire into package.sh (replace the cp)"
