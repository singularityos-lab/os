################################################################################
#
# singularity-splash
#
################################################################################

SINGULARITY_SPLASH_VERSION = d378957d6e66741ceb891f82325f45368da22f16
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
