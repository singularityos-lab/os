################################################################################
#
# singularity-themes
#
################################################################################

SINGULARITY_THEMES_VERSION = b5ce0b98deba5003937da9d923c44bb52082b5f0
SINGULARITY_THEMES_SITE = $(call github,singularityos-lab,singularity-themes,$(SINGULARITY_THEMES_VERSION))
SINGULARITY_THEMES_LICENSE = GPL-3.0+
SINGULARITY_THEMES_LICENSE_FILES = LICENSE
SINGULARITY_THEMES_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
