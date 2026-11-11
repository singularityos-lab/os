################################################################################
#
# singularity-maps
#
################################################################################

SINGULARITY_MAPS_VERSION = f9d75d9e79818b15694a46313d8d24171f46c916
SINGULARITY_MAPS_SITE = $(call github,singularityos-lab,singularity-maps,$(SINGULARITY_MAPS_VERSION))
SINGULARITY_MAPS_LICENSE = GPL-3.0+
SINGULARITY_MAPS_LICENSE_FILES = LICENSE
SINGULARITY_MAPS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsoup3

SINGULARITY_MAPS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
