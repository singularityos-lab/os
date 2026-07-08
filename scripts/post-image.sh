#!/bin/sh
# Buildroot post-image hook. The ISO/UKI/erofs+verity imaging is done by
# scripts/package.sh (run separately, by design). This stub exists so the
# BR2_ROOTFS_POST_IMAGE_SCRIPT reference does not fail with Error 127 -- a
# persistent expected error masks real post-image failures. No-op on purpose.
# $1 = BINARIES_DIR.
exit 0
