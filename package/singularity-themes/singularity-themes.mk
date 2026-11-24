################################################################################
#
# singularity-themes
#
################################################################################

SINGULARITY_THEMES_VERSION = 3fa9d2e803b9973f137e9b73562619d0781757d6
SINGULARITY_THEMES_SITE = $(call github,singularityos-lab,singularity-themes,$(SINGULARITY_THEMES_VERSION))
SINGULARITY_THEMES_LICENSE = GPL-3.0+
SINGULARITY_THEMES_LICENSE_FILES = LICENSE
SINGULARITY_THEMES_DEPENDENCIES = host-pkgconf

SINGULARITY_THEMES_DEPENDENCIES += host-iride
SINGULARITY_THEMES_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
