################################################################################
#
# singularity-wallpapers
#
################################################################################

SINGULARITY_WALLPAPERS_VERSION = 8188d87f08ed8677946827326fda660bedaa0838
SINGULARITY_WALLPAPERS_SITE = $(call github,singularityos-lab,singularity-wallpapers,$(SINGULARITY_WALLPAPERS_VERSION))
SINGULARITY_WALLPAPERS_LICENSE = GPL-3.0+
SINGULARITY_WALLPAPERS_LICENSE_FILES = LICENSE
SINGULARITY_WALLPAPERS_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
