################################################################################
#
# singularity-wallpapers
#
################################################################################

SINGULARITY_WALLPAPERS_VERSION = 8560ef04a7e97ea2900fabbc9b42da0c9201b236
SINGULARITY_WALLPAPERS_SITE = $(call github,singularityos-lab,singularity-wallpapers,$(SINGULARITY_WALLPAPERS_VERSION))
SINGULARITY_WALLPAPERS_LICENSE = GPL-3.0+
SINGULARITY_WALLPAPERS_LICENSE_FILES = LICENSE
SINGULARITY_WALLPAPERS_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
