################################################################################
#
# singularity-boot-splash
#
################################################################################

SINGULARITY_BOOT_SPLASH_VERSION = 324c3fbe1758d07514dc79891b6cc0fe9fa810bd
SINGULARITY_BOOT_SPLASH_SITE = $(call github,singularityos-lab,singularity-boot-splash,$(SINGULARITY_BOOT_SPLASH_VERSION))
SINGULARITY_BOOT_SPLASH_LICENSE = LGPL-2.1
SINGULARITY_BOOT_SPLASH_LICENSE_FILES = LICENSE
SINGULARITY_BOOT_SPLASH_DEPENDENCIES = \
	host-pkgconf \
	singularity-loginui \
	libdrm

$(eval $(meson-package))
