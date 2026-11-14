################################################################################
#
# singularity-themes
#
################################################################################

SINGULARITY_THEMES_VERSION = a00cda23ca22b61f2528180f0e1af34c75fc90bc
SINGULARITY_THEMES_SITE = $(call github,singularityos-lab,singularity-themes,$(SINGULARITY_THEMES_VERSION))
SINGULARITY_THEMES_LICENSE = GPL-3.0+
SINGULARITY_THEMES_LICENSE_FILES = LICENSE
SINGULARITY_THEMES_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
