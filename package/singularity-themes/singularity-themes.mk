################################################################################
#
# singularity-themes
#
################################################################################

SINGULARITY_THEMES_VERSION = 641f7ffab7c41983f1a1f9ac7bca08d773900fa0
SINGULARITY_THEMES_SITE = $(call github,singularityos-lab,singularity-themes,$(SINGULARITY_THEMES_VERSION))
SINGULARITY_THEMES_LICENSE = GPL-3.0+
SINGULARITY_THEMES_LICENSE_FILES = LICENSE
SINGULARITY_THEMES_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
