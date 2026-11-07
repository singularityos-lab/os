################################################################################
#
# singularity-themes
#
################################################################################

SINGULARITY_THEMES_VERSION = d42c3634af2de4867edaa041a365e13d259cf33a
SINGULARITY_THEMES_SITE = $(call github,singularityos-lab,singularity-themes,$(SINGULARITY_THEMES_VERSION))
SINGULARITY_THEMES_LICENSE = GPL-3.0+
SINGULARITY_THEMES_LICENSE_FILES = LICENSE
SINGULARITY_THEMES_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
