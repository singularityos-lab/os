################################################################################
#
# singularity-boot-splash
#
################################################################################

SINGULARITY_BOOT_SPLASH_VERSION = 4d9731ffd1471ad99f77909ee065131b0a3f99f7
SINGULARITY_BOOT_SPLASH_SITE = $(call github,singularityos-lab,singularity-boot-splash,$(SINGULARITY_BOOT_SPLASH_VERSION))
SINGULARITY_BOOT_SPLASH_LICENSE = LGPL-2.1
SINGULARITY_BOOT_SPLASH_LICENSE_FILES = LICENSE
SINGULARITY_BOOT_SPLASH_DEPENDENCIES = \
	host-pkgconf \
	singularity-loginui \
	libdrm \
	seatd

$(eval $(meson-package))
