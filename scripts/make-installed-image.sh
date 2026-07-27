#!/usr/bin/env bash
#
# Build a disk image that looks like an INSTALLED system rather than the live medium.
# Same shape usr/bin/atom-install writes: an ESP and ONE data partition holding the
# root image as a file under boot/rootfs together with the user data that becomes
# /var, plus the .atom-var marker. That marker is what makes the init treat the system
# as installed, which is what arms the update daemon -- so the OTA path can only be
# exercised on an image built this way.
#
# ext4 here rather than f2fs (the initramfs accepts either) so the image can be
# produced without root or f2fs tooling.
#
# OTA_TEST_FEED points the update agent at a throwaway feed and shortens the check
# timer, so an update cycle can be driven end to end against a local server.
#
#   scripts/make-installed-image.sh [out.img]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"
OUT="${1:-artifacts/sinty-installed.img}"
HOSTBIN="${REPO_DIR}/buildroot-build/host/bin"

for f in artifacts/esp.vfat artifacts/rootfs.erofs artifacts/rootfs.hash artifacts/deployment.json; do
	[ -f "$f" ] || { echo "make-installed-image: missing $f (run scripts/package.sh)" >&2; exit 1; }
done

rm -rf artifacts/installed-staging artifacts/atom-data-installed.ext4
mkdir -p artifacts/installed-staging/boot/{rootfs,efi,firmware} \
    artifacts/installed-staging/{home,etc-upper,etc-work,lib,log,cache,spool,tmp,run}
chmod 1777 artifacts/installed-staging/tmp
cp artifacts/rootfs.erofs artifacts/installed-staging/boot/rootfs/rootfs-active.erofs
cp artifacts/rootfs.hash  artifacts/installed-staging/boot/rootfs/rootfs-active.hash
cp artifacts/deployment.json artifacts/installed-staging/boot/rootfs/deployment.json
cp artifacts/deployment.json artifacts/installed-staging/boot/rootfs/deployment.json.bak
: > artifacts/installed-staging/.atom-var

# Unit overrides go in the /etc overlay upper, the same place a local admin change
# would land, so the image itself stays untouched.
if [ -n "${OTA_TEST_FEED:-}" ]; then
	mkdir -p artifacts/installed-staging/etc-upper/systemd/system
	cat > artifacts/installed-staging/etc-upper/systemd/system/updated-check.service <<EOF
[Unit]
Description=Sinty OS update check and fetch (test feed)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
# Staging an update downloads the whole root image, which outlasts a default start
# timeout on a slow link.
TimeoutStartSec=3600
ExecStart=/usr/libexec/updated poll --feed ${OTA_TEST_FEED}
EOF
	cat > artifacts/installed-staging/etc-upper/systemd/system/updated-check.timer <<'EOF'
[Unit]
Description=Periodically check and fetch Sinty OS updates (test cadence)

[Timer]
OnBootSec=20s
OnUnitActiveSec=10min

[Install]
WantedBy=timers.target
EOF
	echo "[make-installed-image] update feed: ${OTA_TEST_FEED}"
fi

# Room for a staged update beside the running image: on a real install the partition
# takes the rest of the disk, here it is sized explicitly.
DATA_MB=$(( $(du -sm artifacts/installed-staging | cut -f1) * 2 + 512 ))
# fakeroot so the tree lands owned by root: mke2fs -d copies the staging ownership.
"${HOSTBIN}/fakeroot" -- sh -c "chown -R 0:0 artifacts/installed-staging && \
    /usr/sbin/mke2fs -q -t ext4 -L atom-data -d artifacts/installed-staging \
    artifacts/atom-data-installed.ext4 ${DATA_MB}M"
rm -rf artifacts/installed-staging

cat > artifacts/genimage-installed.cfg <<'CFG'
image sinty-installed.img {
	hdimage {
		partition-table-type = "gpt"
	}

	partition esp {
		partition-type-uuid = "c12a7328-f81f-11d2-ba4b-00a0c93ec93b"
		image = "esp.vfat"
		bootable = "true"
	}

	partition atom-data {
		partition-type-uuid = "0fc63daf-8483-4772-8e79-3d69d8477de4"
		image = "atom-data-installed.ext4"
	}
}
CFG

rm -rf genimage-installed-tmp
"${HOSTBIN}/genimage" \
    --config artifacts/genimage-installed.cfg \
    --inputpath artifacts \
    --outputpath artifacts \
    --tmppath genimage-installed-tmp
rm -rf genimage-installed-tmp

[ "$OUT" = "artifacts/sinty-installed.img" ] || mv artifacts/sinty-installed.img "$OUT"
echo "[make-installed-image] $OUT"
