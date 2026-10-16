################################################################################
#
# singularity-splash
#
################################################################################

SINGULARITY_SPLASH_VERSION = ded88d777ecdc791ccc977b6c70a76a5e0e9d512
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
