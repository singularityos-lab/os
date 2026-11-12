#!/usr/bin/env bash

set -euo pipefail

prev=$(realpath "$1")
new=$(realpath "$2")
work=$(realpath -m "$3")
: "${PREV_VERSION:?}" "${NEW_VERSION:?}" "${APPLY_CLASS:?}" "${KERNEL_RELEASE:?}"
: "${ATOM_SIGN:?}" "${SIGNING_KEY:?}" "${SIGNING_CERT:?}"
port=${FEED_PORT:-8799}
url=http://10.0.2.2:$port
here=$(cd "$(dirname "$0")" && pwd)
session=
case "$APPLY_CLASS" in reload | relogin) session=1 ;; esac

rm -rf "$work"
mkdir -p "$work/feed" "$work/staging"
cd "$work"

objcopy -O binary --only-section=.linux "$prev/kernelcache.efi" bzImage
objcopy -O binary --only-section=.initrd "$prev/kernelcache.efi" initrd
objcopy -O binary --only-section=.cmdline "$prev/kernelcache.efi" cmdline.bin
cmdline=$(tr -d '\0' < cmdline.bin | sed -e 's/ quiet//' -e 's/loglevel=0/loglevel=4/')
case "$cmdline" in
*"atom.version=$PREV_VERSION"*) ;;
*) echo "live-vm-test: $prev/kernelcache.efi is not $PREV_VERSION" >&2; exit 1 ;;
esac

for f in rootfs.erofs rootfs.hash kernelcache.efi kernelcache.efi.sig; do
	ln -f "$new/$f" "feed/$f" 2>/dev/null || cp "$new/$f" "feed/$f"
done
verity=${NEW_ROOT_HASH:-$(awk '/Root hash:/{print $3}' "$new/verity-output.txt" 2>/dev/null)}
[ -n "$verity" ] || { echo "live-vm-test: no root hash for $NEW_VERSION" >&2; exit 1; }
"$ATOM_SIGN" manifest --out feed/manifest.json --version "$NEW_VERSION" --min-version "$PREV_VERSION" \
	--arch x86_64 --kernel-release "$KERNEL_RELEASE" --apply-class "$APPLY_CLASS" --live-from "$PREV_VERSION" \
	--rootfs feed/rootfs.erofs --rootfs-url "$url/rootfs.erofs" --rootfs-verity-hash "$verity" \
	--rootfs-hashtree feed/rootfs.hash --rootfs-hashtree-url "$url/rootfs.hash" \
	--kernelcache feed/kernelcache.efi --kc-url "$url/kernelcache.efi" \
	--kc-sig feed/kernelcache.efi.sig --kc-sig-url "$url/kernelcache.efi.sig" >/dev/null
"$ATOM_SIGN" sign --priv "$SIGNING_KEY" --manifest feed/manifest.json >/dev/null
cp "$SIGNING_CERT" feed/signing-cert.json
cp "$SIGNING_CERT.sig" feed/signing-cert.json.sig

s=staging
mkdir -p $s/boot/rootfs $s/boot/efi $s/boot/firmware $s/home $s/etc-work $s/lib $s/log $s/cache $s/spool $s/tmp $s/run \
	$s/etc-upper/systemd/system/graphical.target.wants
chmod 1777 $s/tmp
cp "$prev/rootfs.erofs" $s/boot/rootfs/rootfs-active.erofs
cp "$prev/rootfs.hash" $s/boot/rootfs/rootfs-active.hash
python3 - "$PREV_VERSION" > $s/boot/rootfs/deployment.json <<'EOF'
import json, sys, time
v = sys.argv[1]
now = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
print(json.dumps({
    "rootfs": {"current": v, "pending": "", "rollback": "", "boot_attempts": 0, "max_attempts": 3,
               "last_known_good": v, "last_known_good_at": now},
    "kernelcache": {"current_version": int(v.lstrip("v")), "pending_version": 0, "state": "stable",
                    "stable_boots": 0, "stable_threshold": 3, "format": "uki"},
    "firmware": {"bundles": {}},
    "recovery": {"version": "", "path": "", "last_updated": ""},
    "security": {"level": 0, "dm_verity": False, "secure_boot": False, "ima": False, "signing_cert": "",
                 "remote_attestation": False},
    "anti_rollback": {"hardware": "none", "counter_value": 0, "last_updated": ""},
    "orphan_homes": [],
    "recovery_entry": "recovery",
    "meta": {"schema_version": 1, "device_id": "live-vm-test", "channel": "stable", "last_update_check": ""},
}, indent=2))
EOF
cp $s/boot/rootfs/deployment.json $s/boot/rootfs/deployment.json.bak
: > $s/.atom-var
printf '[Unit]\nDescription=Sinty OS update status responder (live test feed)\n\n[Service]\nType=simple\nGroup=singularity-session\nExecStart=/usr/libexec/updated.real serve --feed %s --live-pcr 15\n' "$url" \
	> $s/etc-upper/systemd/system/updated.service
printf '[Unit]\nDescription=Live update test driver\nAfter=updated.service\nWants=updated.service\n\n[Service]\nType=%s\nTimeoutStartSec=3600\nExecStart=/bin/sh /etc/live-vm-test.sh\n' "${session:+simple}" \
	| sed 's/^Type=$/Type=oneshot/' > $s/etc-upper/systemd/system/live-vm-test.service
ln -s ../live-vm-test.service $s/etc-upper/systemd/system/graphical.target.wants/live-vm-test.service
ln -s /dev/null $s/etc-upper/systemd/system/updated-check.timer
if [ -n "$session" ]; then
	cp "$here/live-vm-test-session.sh" $s/etc-upper/live-vm-test.sh
	echo "$APPLY_CLASS" > $s/etc-upper/live-vm-test-class
else
	cp "$here/live-vm-test-guest.sh" $s/etc-upper/live-vm-test.sh
fi
data_mb=$(( ($(stat -c %s "$prev/rootfs.erofs") + $(stat -c %s "$new/rootfs.erofs")) / 1048576 + 1536 ))
mke2fs -q -t ext4 -O encrypt -L atom-data -d $s data.ext4 "${data_mb}M"
rm -rf $s

mkfs.vfat -C -n ESP esp.vfat 262144 >/dev/null
mmd -i esp.vfat ::EFI ::EFI/BOOT ::EFI/atom
mcopy -i esp.vfat "$prev/kernelcache.efi" ::EFI/atom/kernelcache-active.efi
mcopy -i esp.vfat "$prev/kernelcache.efi.sig" ::EFI/atom/kernelcache-active.efi.sig
mcopy -i esp.vfat "$SIGNING_CERT" ::EFI/atom/signing-cert.json

data_sectors=$(( $(stat -c %s data.ext4) / 512 ))
truncate -s $(( (526336 + data_sectors + 2048) * 512 )) disk.raw
printf 'label: gpt\nstart=2048, size=524288, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name=esp\nstart=526336, size=%s, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=atom-data\n' "$data_sectors" | sfdisk -q disk.raw
dd if=esp.vfat of=disk.raw bs=512 seek=2048 conv=notrunc,sparse status=none
dd if=data.ext4 of=disk.raw bs=512 seek=526336 conv=notrunc,sparse status=none
rm -f data.ext4 esp.vfat

mkdir -p tpm shots
python3 -m http.server "$port" --bind 0.0.0.0 --directory "$work/feed" > http.log 2>&1 &
http=$!
accel=tcg
[ -w /dev/kvm ] && accel=kvm
vm() {
	rm -f "$work/qmp.sock" "$work/tpm.sock"
	swtpm socket --tpm2 --tpmstate dir="$work/tpm" --ctrl type=unixio,path="$work/tpm.sock" --flags startup-clear --pid file="$work/swtpm.pid" --daemon
	for _ in $(seq 20); do [ -S "$work/tpm.sock" ] && break; sleep 0.3; done
	timeout "${LIVE_TEST_TIMEOUT:-1800}" qemu-system-x86_64 -machine q35,accel=$accel -cpu max -smp 4 -m 6144 \
		-kernel bzImage -initrd initrd -append "$cmdline" \
		-drive file="$work/disk.raw",if=none,id=nvme0,format=raw,cache=unsafe -device nvme,serial=livetest,drive=nvme0 \
		-chardev socket,id=chrtpm,path="$work/tpm.sock" -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0 \
		-device virtio-vga -display none -device qemu-xhci -device usb-tablet -device usb-kbd \
		-netdev user,id=n0 -device virtio-net-pci,netdev=n0 \
		-qmp unix:"$work/qmp.sock",server,nowait -serial file:"$work/serial-$1.log" -no-reboot </dev/null > "qemu-$1.out" 2>&1
	vmrc=$?
	[ -f "$work/swtpm.pid" ] && kill "$(cat "$work/swtpm.pid")" 2>/dev/null
	rm -f "$work/swtpm.pid"
	return $vmrc
}
qmp() { python3 "$here/live-vm-qmp.py" "$work/qmp.sock" "$@" || true; }
pause() { sleep "$1"; }
xy() { echo "$1" | tr ',' ' '; }
drive() {
	pause 60
	qmp shot "$work/shots/01-greeter.png"
	qmp click $(xy "${LIVE_PIN_XY:-805,430}")
	qmp type 123456
	qmp key ret
	pause 45
	qmp shot "$work/shots/02-desktop.png"
	qmp click $(xy "${LIVE_APP_XY:-763,748}")
	pause 8
	qmp move 1000 300
	n=0
	while ! grep -q "kernelcache.efi.sig" http.log && [ $n -lt 900 ]; do pause 5; n=$((n + 5)); done
	pause 20
	qmp move $(xy "${LIVE_UPDATE_XY:-907,748}")
	pause 4
	qmp shot "$work/shots/03-ready.png"
	qmp click $(xy "${LIVE_UPDATE_XY:-907,748}")
	pause 4
	qmp shot "$work/shots/04-confirm.png"
	qmp click $(xy "${LIVE_CONFIRM_XY:-709,480}")
	if [ "$APPLY_CLASS" = relogin ]; then
		for n in 1 2 3 4 5 6 7 8 9 10; do pause 2; qmp shot "$work/shots/05-relogin-$n.png"; done
		pause 30
		qmp shot "$work/shots/06-greeter.png"
		qmp click $(xy "${LIVE_PIN_XY:-805,430}")
		qmp type 123456
		qmp key ret
		pause 45
	else
		pause 20
	fi
	qmp move 600 400
	qmp shot "$work/shots/07-applied.png"
	qmp key meta_l
	pause 2
	qmp type settings
	pause 2
	qmp key ret
	pause 8
	qmp shot "$work/shots/08-settings.png"
}
rc=0
if [ -n "$session" ]; then
	vm provision || rc=$?
	grep -q "first-boot provisioning complete" serial-provision.log || { echo "live-vm-test: provisioning the test user failed" >&2; rc=1; }
	if [ $rc -eq 0 ]; then
		drive &
		driver=$!
		vm session || rc=$?
		kill $driver 2>/dev/null || true
	fi
else
	vm live || rc=$?
fi
kill $http 2>/dev/null || true
dd if=disk.raw of=data.ext4 bs=512 skip=526336 count="$data_sectors" conv=sparse status=none
debugfs -R "cat /live-vm-test.txt" data.ext4 2>/dev/null > result.txt || true
rm -f data.ext4 disk.raw feed/manifest.json feed/manifest.json.sig
echo "qemu exit $rc"
cat result.txt
grep -qx "RESULT PASS" result.txt
