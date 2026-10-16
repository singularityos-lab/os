################################################################################
#
# singularity-nearby
#
################################################################################

SINGULARITY_NEARBY_VERSION = c17a12a4eea061890598bc45f2c7498696dbc14a
SINGULARITY_NEARBY_SITE = $(call github,singularityos-lab,singularity-nearby,$(SINGULARITY_NEARBY_VERSION))
SINGULARITY_NEARBY_LICENSE = GPL-3.0+
SINGULARITY_NEARBY_LICENSE_FILES = LICENSE
SINGULARITY_NEARBY_DEPENDENCIES = host-pkgconf host-vala libglib2 json-glib libgee gnutls

SINGULARITY_NEARBY_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
