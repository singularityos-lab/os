################################################################################
#
# singularity-boot-splash
#
################################################################################

SINGULARITY_BOOT_SPLASH_VERSION = 95a8f685a3d020fbb3cd8d585d38b8085c49ffe3
SINGULARITY_BOOT_SPLASH_SITE = $(call github,singularityos-lab,singularity-boot-splash,$(SINGULARITY_BOOT_SPLASH_VERSION))
SINGULARITY_BOOT_SPLASH_LICENSE = LGPL-2.1
SINGULARITY_BOOT_SPLASH_LICENSE_FILES = LICENSE
SINGULARITY_BOOT_SPLASH_DEPENDENCIES = \
	host-pkgconf \
	singularity-loginui \
	libdrm \
	seatd

$(eval $(meson-package))
