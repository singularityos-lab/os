################################################################################
#
# singularity-splash
#
################################################################################

SINGULARITY_SPLASH_VERSION = 6a15563da7e0a9cd79f8869a0f269491f7df3bb6
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
