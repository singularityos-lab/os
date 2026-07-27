#!/usr/bin/env bash
#
# Build a disk image that looks like an INSTALLED system, not the live medium:
# ESP + atom-system (the rootfs slot files) + a persistent atom-var carrying the
# .atom-var marker. That marker is what makes the init write /run/atom/installed,
# and without it the OTA daemon stays inert -- so the update path can only be
# exercised on an image built this way. Mirrors the layout usr/bin/atom-install
# writes, without needing a real install run.
#
# /var is ext4 here rather than f2fs (the initramfs accepts either) so the image
# can be produced without root or f2fs tooling.
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

for f in artifacts/esp.vfat artifacts/atom-system.ext4; do
	[ -f "$f" ] || { echo "make-installed-image: missing $f (run scripts/package.sh)" >&2; exit 1; }
done

# The persistent /var an installed system boots with. The directory set matches
# what the installer creates; .atom-var is the installed-vs-live signal.
rm -rf artifacts/var-staging artifacts/atom-var.ext4
mkdir -p artifacts/var-staging/{home,etc-upper,etc-work,lib,log,cache,spool,tmp,run}
: > artifacts/var-staging/.atom-var
chmod 1777 artifacts/var-staging/tmp

# Unit overrides go in the /etc overlay upper, the same place a local admin change
# would land, so the image itself stays untouched.
if [ -n "${OTA_TEST_FEED:-}" ]; then
	mkdir -p artifacts/var-staging/etc-upper/systemd/system
	cat > artifacts/var-staging/etc-upper/systemd/system/updated-check.service <<EOF
[Unit]
Description=Sinty OS update check and fetch (test feed)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
# Staging an update downloads the whole root image, which outlasts a default
# start timeout on a slow link.
TimeoutStartSec=3600
ExecStart=/usr/libexec/updated poll --feed ${OTA_TEST_FEED}
EOF
	cat > artifacts/var-staging/etc-upper/systemd/system/updated-check.timer <<'EOF'
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

# fakeroot so the tree lands owned by root: mke2fs -d copies the staging ownership.
"${HOSTBIN}/fakeroot" -- sh -c "chown -R 0:0 artifacts/var-staging && \
    /usr/sbin/mke2fs -q -t ext4 -L atom-var -d artifacts/var-staging artifacts/atom-var.ext4 512M"
rm -rf artifacts/var-staging

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

	partition atom-system {
		partition-type-uuid = "0fc63daf-8483-4772-8e79-3d69d8477de4"
		image = "atom-system.ext4"
	}

	partition atom-var {
		partition-type-uuid = "0fc63daf-8483-4772-8e79-3d69d8477de4"
		image = "atom-var.ext4"
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
