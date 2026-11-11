################################################################################
#
# singularity-formula
#
################################################################################

SINGULARITY_FORMULA_VERSION = 0fac0b5c2ef53158e2818b1039bf2901d115b03c
SINGULARITY_FORMULA_SITE = $(call github,singularityos-lab,singularity-formula,$(SINGULARITY_FORMULA_VERSION))
SINGULARITY_FORMULA_LICENSE = GPL-3.0+
SINGULARITY_FORMULA_LICENSE_FILES = LICENSE
SINGULARITY_FORMULA_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo fontconfig freetype libgee harfbuzz libxml2 pango zlib

SINGULARITY_FORMULA_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
