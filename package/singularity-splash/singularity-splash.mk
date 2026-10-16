################################################################################
#
# singularity-splash
#
################################################################################

SINGULARITY_SPLASH_VERSION = b1a1a1e3e80939f7bf0754d45f43283d2198c013
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
