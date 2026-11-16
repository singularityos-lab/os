################################################################################
#
# singularity-colorpicker
#
################################################################################

SINGULARITY_COLORPICKER_VERSION = ff5b6b245d8fa29ff2909a1d3a1dfe356aeb8027
SINGULARITY_COLORPICKER_SITE = $(call github,singularityos-lab,singularity-colorpicker,$(SINGULARITY_COLORPICKER_VERSION))
SINGULARITY_COLORPICKER_LICENSE = GPL-3.0+
SINGULARITY_COLORPICKER_LICENSE_FILES = LICENSE
SINGULARITY_COLORPICKER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libpeas2

SINGULARITY_COLORPICKER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
