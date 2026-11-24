################################################################################
#
# singularity-nearby-app
#
################################################################################

SINGULARITY_NEARBY_APP_VERSION = 1b6c0d0f37e75a634bd655d49fd360e7f69a4169
SINGULARITY_NEARBY_APP_SITE = $(call github,singularityos-lab,singularity-nearby-app,$(SINGULARITY_NEARBY_APP_VERSION))
SINGULARITY_NEARBY_APP_LICENSE = GPL-3.0+
SINGULARITY_NEARBY_APP_LICENSE_FILES = LICENSE
SINGULARITY_NEARBY_APP_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee singularity-nearby

SINGULARITY_NEARBY_APP_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
