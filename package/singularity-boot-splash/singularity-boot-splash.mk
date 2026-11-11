################################################################################
#
# singularity-boot-splash
#
################################################################################

SINGULARITY_BOOT_SPLASH_VERSION = dabf0fb619dcfbed2a4cf00f3a7589acfeaff723
SINGULARITY_BOOT_SPLASH_SITE = $(call github,singularityos-lab,singularity-boot-splash,$(SINGULARITY_BOOT_SPLASH_VERSION))
SINGULARITY_BOOT_SPLASH_LICENSE = LGPL-2.1
SINGULARITY_BOOT_SPLASH_LICENSE_FILES = LICENSE
SINGULARITY_BOOT_SPLASH_DEPENDENCIES = \
	host-pkgconf \
	singularity-loginui \
	libdrm \
	seatd

$(eval $(meson-package))
