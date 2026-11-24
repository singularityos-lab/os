################################################################################
#
# singularity-themes
#
################################################################################

SINGULARITY_THEMES_VERSION = 32c9c3ccbcfb99ba2425723f0711480f20732bcd
SINGULARITY_THEMES_SITE = $(call github,singularityos-lab,singularity-themes,$(SINGULARITY_THEMES_VERSION))
SINGULARITY_THEMES_LICENSE = GPL-3.0+
SINGULARITY_THEMES_LICENSE_FILES = LICENSE
SINGULARITY_THEMES_DEPENDENCIES = host-pkgconf

SINGULARITY_THEMES_DEPENDENCIES += host-iride
SINGULARITY_THEMES_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
