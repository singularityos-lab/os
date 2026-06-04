################################################################################
#
# singularity-wallpapers
#
################################################################################

SINGULARITY_WALLPAPERS_VERSION = ab461018a13565cd70e2231634e4d181ad7e3aff
SINGULARITY_WALLPAPERS_SITE = $(call github,singularityos-lab,singularity-wallpapers,$(SINGULARITY_WALLPAPERS_VERSION))
SINGULARITY_WALLPAPERS_LICENSE = GPL-3.0+
SINGULARITY_WALLPAPERS_LICENSE_FILES = LICENSE
SINGULARITY_WALLPAPERS_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
