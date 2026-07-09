#!/bin/sh

TARGET_DIR="$1"

# Restore merged-usr: stray real-file installs (e.g. keyutils' /bin/keyctl) can turn the
# /bin and /sbin merge symlinks into real directories, which breaks the rootfs devices
# table (/bin/busybox) and the kernel modprobe path (/sbin -> /usr/sbin). Re-merge them.
for _d in bin sbin; do
    if [ -d "$TARGET_DIR/$_d" ] && [ ! -L "$TARGET_DIR/$_d" ]; then
        cp -a "$TARGET_DIR/$_d/." "$TARGET_DIR/usr/$_d/" 2>/dev/null || true
        rm -rf "$TARGET_DIR/$_d"
        ln -sf "usr/$_d" "$TARGET_DIR/$_d"
    fi
done


# Ensure the GSettings schema sources are present in the target (some packages
# install them only into staging), then compile the cache. Without a valid
# gschemas.compiled, GTK4/glib apps abort with SIGTRAP on first schema access.
_STG="$(dirname "$TARGET_DIR")/staging/usr/share/glib-2.0/schemas"
_TGT="$TARGET_DIR/usr/share/glib-2.0/schemas"
mkdir -p "$_TGT"
if [ -d "$_STG" ]; then
    cp -f "$_STG"/*.gschema.xml "$_TGT/" 2>/dev/null || true
    cp -f "$_STG"/*.enums.xml "$_TGT/" 2>/dev/null || true
fi
"$(dirname "$TARGET_DIR")/host/bin/glib-compile-schemas" "$_TGT" >/dev/null 2>&1 || true

# GIO module cache: without it, glib-networking's TLS backend (libgio{gnutls,openssl})
# is not registered, so libsoup (the Store's HTTP client) cannot do HTTPS. The rootfs
# is read-only at runtime, so the cache must be baked here.
_GIOMOD="$TARGET_DIR/usr/lib/gio/modules"
if [ -d "$_GIOMOD" ]; then
    "$(dirname "$TARGET_DIR")/host/bin/gio-querymodules" "$_GIOMOD" >/dev/null 2>&1 || true
fi

echo "[singularity] post-build: cleaning rootfs..."

# Remove docs
rm -rf "$TARGET_DIR/usr/share/doc"
rm -rf "$TARGET_DIR/usr/share/man"
rm -rf "$TARGET_DIR/usr/share/info"
rm -rf "$TARGET_DIR/usr/share/locale"

# Remove headers
rm -rf "$TARGET_DIR/usr/include"

rm -f "$TARGET_DIR/usr/share/wayland-sessions/labwc.desktop"

# Remove static libs
find "$TARGET_DIR" -name "*.a" -delete
find "$TARGET_DIR" -name "*.la" -delete

# Strip binaries
find "$TARGET_DIR/usr/bin" -type f -exec strip --strip-all {} \; 2>/dev/null || true
find "$TARGET_DIR/usr/sbin" -type f -exec strip --strip-all {} \; 2>/dev/null || true
find "$TARGET_DIR/bin" -type f -exec strip --strip-all {} \; 2>/dev/null || true
find "$TARGET_DIR/sbin" -type f -exec strip --strip-all {} \; 2>/dev/null || true

# Helper paths: pam_unix and getty look in /usr/sbin, binaries are in /usr/bin
for b in unix_chkpwd agetty; do
	if [ -e "$TARGET_DIR/usr/bin/$b" ] && [ ! -e "$TARGET_DIR/usr/sbin/$b" ]; then
		ln -sf "../bin/$b" "$TARGET_DIR/usr/sbin/$b"
	fi
done

echo "[singularity] post-build: done. Rootfs size: $(du -sh $TARGET_DIR | cut -f1)"

# Some new packages (udisks/deps) drop /etc/ld.so.conf(.d); buildroot's target-finalize
# rejects them on a glibc-merged target. Remove so finalize passes.
rm -f "$TARGET_DIR/etc/ld.so.conf"
rm -rf "$TARGET_DIR/etc/ld.so.conf.d"

# The kernel's request_module() uses CONFIG_MODPROBE_PATH=/sbin/modprobe (= /usr/sbin/modprobe
# via the /sbin->usr/sbin merge). Buildroot ships modprobe only in /usr/bin, so kernel-initiated
# module autoload (iwlmvm -> wlan0, etc.) silently fails. Provide the sbin entrypoints.
for _t in modprobe depmod insmod rmmod lsmod; do
    ln -sf /usr/bin/kmod "$TARGET_DIR/usr/sbin/$_t"
done

mkdir -p "$TARGET_DIR/var/cache/fontconfig"

# De-systemd: install the libsystemd shim as /usr/lib/libsystemd.so.0 (the 66 sd_* consumers
# link it by SONAME; with systemd removed nothing else provides it). + systemctl->sinit alias.
_SHIM="$(ls "$HOME"/Documents/atom-loops-gold/libsystemd-shim/libsystemd.so.0* 2>/dev/null | head -1)"
if [ -n "$_SHIM" ]; then
    cp "$_SHIM" "$TARGET_DIR/usr/lib/libsystemd.so.0"
    ln -sf libsystemd.so.0 "$TARGET_DIR/usr/lib/libsystemd.so"
fi

# De-systemd: purge stale systemd files the incremental build leaves behind (buildroot does
# not remove a disabled package's target files). sinit is PID1; systemd's units/binaries must
# not linger (sinit reads *.target.wants and would trip on stale units). The shim's
# libsystemd.so.0 stays; the real 0.41.0 and the systemd tree go.
# SURGICAL: remove only the systemd daemon executables + the real libsystemd; KEEP the unit
# files under /usr/lib/systemd/system and /etc/systemd/system -- sinit READS those (services +
# *.target.wants). Wiping them left graphical.target empty (no services started).
find "$TARGET_DIR/usr/lib/systemd" -maxdepth 1 -type f -name 'systemd*' -delete 2>/dev/null || true
rm -f "$TARGET_DIR/usr/lib/libsystemd.so.0.41.0" "$TARGET_DIR/usr/bin/init" 2>/dev/null || true
rm -rf "$TARGET_DIR/usr/lib/systemd/user" 2>/dev/null || true
# keep our systemctl->sinit alias

# NetworkManager refuses keyfile connections that are not 0600; the overlay copy lands 0644.
chmod 600 "$TARGET_DIR"/etc/NetworkManager/system-connections/*.nmconnection 2>/dev/null || true

# atom-probe key/token must stay 0600 (overlay copy lands 0644); dir 0700.
chmod 700 "$TARGET_DIR/root/.atom-probe" 2>/dev/null || true
chmod 600 "$TARGET_DIR"/root/.atom-probe/token "$TARGET_DIR"/root/.atom-probe/probe.key 2>/dev/null || true

# Ubuntu-parity firmware (FB-10): the buildroot linux-firmware selection ships only a few
# blobs (whack-a-mole per machine). A general OS ships a broad set so drivers already in
# the kernel can init generic wifi/GPU/BT out of the box; per-card verification stays a
# hardware test, this only provides the capability. Mode: none | curated | full.
_FW_MODE="curated"
_FW_SRC="$(ls -d "$(dirname "$TARGET_DIR")"/build/linux-firmware-*/ 2>/dev/null | head -1)"
if [ "$_FW_MODE" != "none" ] && [ -n "$_FW_SRC" ] && [ -d "$_FW_SRC" ]; then
    _FW_DST="$TARGET_DIR/usr/lib/firmware"
    mkdir -p "$_FW_DST"
    # Use upstream copy-firmware.sh so the WHENCE Link: entries become the flat symlinks
    # the drivers request (e.g. iwlwifi-so-a0-hr-b0-89.ucode -> intel/iwlwifi/...).
    if [ -f "$_FW_SRC/copy-firmware.sh" ]; then
        ( cd "$_FW_SRC" && sh ./copy-firmware.sh "$_FW_DST" ) >/dev/null 2>&1 || cp -a "$_FW_SRC"/. "$_FW_DST"/ 2>/dev/null
    else
        cp -a "$_FW_SRC"/. "$_FW_DST"/ 2>/dev/null || true
    fi
    if [ "$_FW_MODE" = "curated" ]; then
        # keep all wifi/GPU/BT/Intel-audio; drop server NICs, video codecs, cameras,
        # obscure SoC/modem blobs a laptop desktop never loads.
        rm -rf "$_FW_DST"/netronome "$_FW_DST"/mellanox "$_FW_DST"/qed "$_FW_DST"/bnx2x \
               "$_FW_DST"/liquidio "$_FW_DST"/cxgb4 "$_FW_DST"/dpaa2 "$_FW_DST"/br-firmware.tar \
               "$_FW_DST"/qcom "$_FW_DST"/ti-connectivity "$_FW_DST"/ueagle-atm \
               "$_FW_DST"/dsp56k "$_FW_DST"/matrox "$_FW_DST"/ositech 2>/dev/null || true
    fi
    rm -rf "$_FW_DST/.git" "$_FW_DST/check_whence.py" "$_FW_DST"/*.rst 2>/dev/null || true
fi

# RC hardening: the dev markers gate dev-only units -- /etc/atom/dev.enabled fences the
# root-vt/diag-console root shells (ConditionPathExists) and the dev toolkit;
# probe.enabled fences atom-probe. A release image must NOT ship them, or those gates are
# always-true and the root-shell backdoor is fenced only by the fragile sinit target-wants
# gap. Dev images (ATOM_BUILD unset) keep the markers; ATOM_BUILD=rc strips them, so on the
# RC `ls /etc/atom/` is empty and no root shell can land on a VT. Runs after the overlay is
# copied, so it removes what the overlay placed.
if [ "${ATOM_BUILD:-}" = "rc" ]; then
    rm -f "$TARGET_DIR/etc/atom/dev.enabled" "$TARGET_DIR/etc/atom/probe.enabled"
    rm -f "$TARGET_DIR/usr/bin/sinty-devlink" "$TARGET_DIR/usr/bin/sinty-online" "$TARGET_DIR/usr/sbin/dropbear" "$TARGET_DIR/usr/sbin/dropbearkey"
    rm -rf "$TARGET_DIR/usr/share/atom/devlink"
    echo "[singularity] post-build: RC build -- stripped dev markers (dev.enabled, probe.enabled)"
fi
