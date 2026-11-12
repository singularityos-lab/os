################################################################################
#
# singularity-boot-splash
#
################################################################################

SINGULARITY_BOOT_SPLASH_VERSION = b6d009da0b7f822d152a619fc13df00b509454f5
SINGULARITY_BOOT_SPLASH_SITE = $(call github,singularityos-lab,singularity-boot-splash,$(SINGULARITY_BOOT_SPLASH_VERSION))
SINGULARITY_BOOT_SPLASH_LICENSE = LGPL-2.1
SINGULARITY_BOOT_SPLASH_LICENSE_FILES = LICENSE
SINGULARITY_BOOT_SPLASH_DEPENDENCIES = \
	host-pkgconf \
	singularity-loginui \
	libdrm \
	seatd

$(eval $(meson-package))
