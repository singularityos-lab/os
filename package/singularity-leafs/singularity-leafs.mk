################################################################################
#
# singularity-leafs
#
################################################################################

SINGULARITY_LEAFS_VERSION = 0fee10cd44b095f49a19b9c03f3c0d21a63cefa3
SINGULARITY_LEAFS_SITE = $(call github,singularityos-lab,singularity-leafs,$(SINGULARITY_LEAFS_VERSION))
SINGULARITY_LEAFS_LICENSE = GPL-3.0+
SINGULARITY_LEAFS_LICENSE_FILES = LICENSE
SINGULARITY_LEAFS_INSTALL_STAGING = YES
SINGULARITY_LEAFS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee vte-gtk4 json-glib

SINGULARITY_LEAFS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
