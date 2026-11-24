################################################################################
#
# singularity-wallpapers
#
################################################################################

SINGULARITY_WALLPAPERS_VERSION = 2e98d705d73fa7fb352c9daa1f3b0738e74bda72
SINGULARITY_WALLPAPERS_SITE = $(call github,singularityos-lab,singularity-wallpapers,$(SINGULARITY_WALLPAPERS_VERSION))
SINGULARITY_WALLPAPERS_LICENSE = GPL-3.0+
SINGULARITY_WALLPAPERS_LICENSE_FILES = LICENSE
SINGULARITY_WALLPAPERS_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
