################################################################################
#
# singularity-themes
#
################################################################################

SINGULARITY_THEMES_VERSION = 1b0e7e716e3d7b7742845e1ea88083a233a252d0
SINGULARITY_THEMES_SITE = $(call github,singularityos-lab,singularity-themes,$(SINGULARITY_THEMES_VERSION))
SINGULARITY_THEMES_LICENSE = GPL-3.0+
SINGULARITY_THEMES_LICENSE_FILES = LICENSE
SINGULARITY_THEMES_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
