################################################################################
#
# singularity-leafs
#
################################################################################

SINGULARITY_LEAFS_VERSION = 2ac6b66b0d47de08b543572272a5ce34dbe8a62f
SINGULARITY_LEAFS_SITE = $(call github,singularityos-lab,singularity-leafs,$(SINGULARITY_LEAFS_VERSION))
SINGULARITY_LEAFS_LICENSE = GPL-3.0+
SINGULARITY_LEAFS_LICENSE_FILES = LICENSE
SINGULARITY_LEAFS_INSTALL_STAGING = YES
SINGULARITY_LEAFS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee vte-gtk4 json-glib

SINGULARITY_LEAFS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
