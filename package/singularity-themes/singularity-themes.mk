################################################################################
#
# singularity-themes
#
################################################################################

SINGULARITY_THEMES_VERSION = 63a3318bea5a598cb17e8e66598ec24f68d66cca
SINGULARITY_THEMES_SITE = $(call github,singularityos-lab,singularity-themes,$(SINGULARITY_THEMES_VERSION))
SINGULARITY_THEMES_LICENSE = GPL-3.0+
SINGULARITY_THEMES_LICENSE_FILES = LICENSE
SINGULARITY_THEMES_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
