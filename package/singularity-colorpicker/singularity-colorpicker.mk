################################################################################
#
# singularity-colorpicker
#
################################################################################

SINGULARITY_COLORPICKER_VERSION = 2e8be8eb173eb0fcbd1fe453483b1cb8951e1fba
SINGULARITY_COLORPICKER_SITE = $(call github,singularityos-lab,singularity-colorpicker,$(SINGULARITY_COLORPICKER_VERSION))
SINGULARITY_COLORPICKER_LICENSE = GPL-3.0+
SINGULARITY_COLORPICKER_LICENSE_FILES = LICENSE
SINGULARITY_COLORPICKER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libpeas2

SINGULARITY_COLORPICKER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
