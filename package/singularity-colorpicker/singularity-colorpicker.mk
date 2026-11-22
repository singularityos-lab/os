################################################################################
#
# singularity-colorpicker
#
################################################################################

SINGULARITY_COLORPICKER_VERSION = 91dc9af30a317e6e7def842eb75fe22b79baaacb
SINGULARITY_COLORPICKER_SITE = $(call github,singularityos-lab,singularity-colorpicker,$(SINGULARITY_COLORPICKER_VERSION))
SINGULARITY_COLORPICKER_LICENSE = GPL-3.0+
SINGULARITY_COLORPICKER_LICENSE_FILES = LICENSE
SINGULARITY_COLORPICKER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libpeas2

SINGULARITY_COLORPICKER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_COLORPICKER_DEPENDENCIES += host-iride
SINGULARITY_COLORPICKER_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
