################################################################################
#
# singularity-leafs
#
################################################################################

SINGULARITY_LEAFS_VERSION = 4f9244173d6b0d493d1de3dfc670593a15809b8e
SINGULARITY_LEAFS_SITE = $(call github,singularityos-lab,singularity-leafs,$(SINGULARITY_LEAFS_VERSION))
SINGULARITY_LEAFS_LICENSE = GPL-3.0+
SINGULARITY_LEAFS_LICENSE_FILES = LICENSE
SINGULARITY_LEAFS_INSTALL_STAGING = YES
SINGULARITY_LEAFS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee vte-gtk4 json-glib

SINGULARITY_LEAFS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
