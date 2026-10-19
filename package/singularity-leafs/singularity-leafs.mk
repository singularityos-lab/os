################################################################################
#
# singularity-leafs
#
################################################################################

SINGULARITY_LEAFS_VERSION = 5e8316b0f2a2e23763dd1d21687058d9e06d184a
SINGULARITY_LEAFS_SITE = $(call github,singularityos-lab,singularity-leafs,$(SINGULARITY_LEAFS_VERSION))
SINGULARITY_LEAFS_LICENSE = GPL-3.0+
SINGULARITY_LEAFS_LICENSE_FILES = LICENSE
SINGULARITY_LEAFS_INSTALL_STAGING = YES
SINGULARITY_LEAFS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee vte-gtk4 json-glib

SINGULARITY_LEAFS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
