################################################################################
#
# singularity-colorpicker
#
################################################################################

SINGULARITY_COLORPICKER_VERSION = 766f863e19445bef2f128199b22eed501c63ec1a
SINGULARITY_COLORPICKER_SITE = $(call github,singularityos-lab,singularity-colorpicker,$(SINGULARITY_COLORPICKER_VERSION))
SINGULARITY_COLORPICKER_LICENSE = GPL-3.0+
SINGULARITY_COLORPICKER_LICENSE_FILES = LICENSE
SINGULARITY_COLORPICKER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libpeas2

SINGULARITY_COLORPICKER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
