################################################################################
#
# singularity-wallpapers
#
################################################################################

SINGULARITY_WALLPAPERS_VERSION = 422f24176489f97192c0552230020390a4e33a32
SINGULARITY_WALLPAPERS_SITE = $(call github,singularityos-lab,singularity-wallpapers,$(SINGULARITY_WALLPAPERS_VERSION))
SINGULARITY_WALLPAPERS_LICENSE = GPL-3.0+
SINGULARITY_WALLPAPERS_LICENSE_FILES = LICENSE
SINGULARITY_WALLPAPERS_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
