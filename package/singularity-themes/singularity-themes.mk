################################################################################
#
# singularity-themes
#
################################################################################

SINGULARITY_THEMES_VERSION = b9ea0198fd1a6eb7730ebd2653692a709a6186bc
SINGULARITY_THEMES_SITE = $(call github,singularityos-lab,singularity-themes,$(SINGULARITY_THEMES_VERSION))
SINGULARITY_THEMES_LICENSE = GPL-3.0+
SINGULARITY_THEMES_LICENSE_FILES = LICENSE
SINGULARITY_THEMES_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
