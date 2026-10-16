################################################################################
#
# singularity-formula
#
################################################################################

SINGULARITY_FORMULA_VERSION = 521a402416244124e34395c5ee61b59a79c4ff6c
SINGULARITY_FORMULA_SITE = $(call github,singularityos-lab,singularity-formula,$(SINGULARITY_FORMULA_VERSION))
SINGULARITY_FORMULA_LICENSE = GPL-3.0+
SINGULARITY_FORMULA_LICENSE_FILES = LICENSE
SINGULARITY_FORMULA_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo fontconfig freetype libgee harfbuzz libxml2 pango zlib

SINGULARITY_FORMULA_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
