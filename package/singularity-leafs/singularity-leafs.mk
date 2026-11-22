################################################################################
#
# singularity-leafs
#
################################################################################

SINGULARITY_LEAFS_VERSION = 5c0c74a3b7a921a7c5a9fc98f3032a46aaee2dce
SINGULARITY_LEAFS_SITE = $(call github,singularityos-lab,singularity-leafs,$(SINGULARITY_LEAFS_VERSION))
SINGULARITY_LEAFS_LICENSE = GPL-3.0+
SINGULARITY_LEAFS_LICENSE_FILES = LICENSE
SINGULARITY_LEAFS_INSTALL_STAGING = YES
SINGULARITY_LEAFS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee vte-gtk4 json-glib

SINGULARITY_LEAFS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_LEAFS_DEPENDENCIES += host-iride
SINGULARITY_LEAFS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
