################################################################################
#
# singularity-maps
#
################################################################################

SINGULARITY_MAPS_VERSION = 8a730e50116c360a9b02bc327b65496eec3d8536
SINGULARITY_MAPS_SITE = $(call github,singularityos-lab,singularity-maps,$(SINGULARITY_MAPS_VERSION))
SINGULARITY_MAPS_LICENSE = GPL-3.0+
SINGULARITY_MAPS_LICENSE_FILES = LICENSE
SINGULARITY_MAPS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsoup3

SINGULARITY_MAPS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_MAPS_DEPENDENCIES += host-iride
SINGULARITY_MAPS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
