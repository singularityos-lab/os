################################################################################
#
# singularity-formula
#
################################################################################

SINGULARITY_FORMULA_VERSION = 3cdd8300704e84e36ac9019480630e97fe9abb6d
SINGULARITY_FORMULA_SITE = $(call github,singularityos-lab,singularity-formula,$(SINGULARITY_FORMULA_VERSION))
SINGULARITY_FORMULA_LICENSE = GPL-3.0+
SINGULARITY_FORMULA_LICENSE_FILES = LICENSE
SINGULARITY_FORMULA_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo fontconfig freetype libgee harfbuzz libxml2 pango zlib

SINGULARITY_FORMULA_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_FORMULA_DEPENDENCIES += host-iride
SINGULARITY_FORMULA_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
