#!/bin/sh

TARGET_DIR="$1"

echo "[singularity] post-build: cleaning rootfs..."

# Remove docs
rm -rf "$TARGET_DIR/usr/share/doc"
rm -rf "$TARGET_DIR/usr/share/man"
rm -rf "$TARGET_DIR/usr/share/info"
rm -rf "$TARGET_DIR/usr/share/locale"

# Remove headers
rm -rf "$TARGET_DIR/usr/include"

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
