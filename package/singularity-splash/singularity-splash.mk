################################################################################
#
# singularity-splash
#
################################################################################

SINGULARITY_SPLASH_VERSION = 0f37cd995a5a26f1adf398bbf4b3c32b33d9e207
SINGULARITY_SPLASH_SITE = $(call github,singularityos-lab,singularity-desktop,$(SINGULARITY_SPLASH_VERSION))
SINGULARITY_SPLASH_SUBDIR = subprojects/singularity-splash
SINGULARITY_SPLASH_LICENSE = GPL-3.0+
SINGULARITY_SPLASH_LICENSE_FILES = LICENSE
SINGULARITY_SPLASH_DEPENDENCIES = \
	host-pkgconf \
	host-wayland \
	singularity-loginui \
	wayland

$(eval $(meson-package))
