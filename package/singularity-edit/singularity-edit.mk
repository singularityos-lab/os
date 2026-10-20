################################################################################
#
# singularity-edit
#
################################################################################

SINGULARITY_EDIT_VERSION = efb74273e3e2e2dc151cfb4c9e1b57c2faa050a1
SINGULARITY_EDIT_SITE = $(call github,singularityos-lab,singularity-edit,$(SINGULARITY_EDIT_VERSION))
SINGULARITY_EDIT_LICENSE = GPL-3.0+
SINGULARITY_EDIT_LICENSE_FILES = LICENSE
SINGULARITY_EDIT_INSTALL_STAGING = YES
SINGULARITY_EDIT_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gtksourceview json-glib libsoup3 vte-gtk4 $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk)

SINGULARITY_EDIT_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
