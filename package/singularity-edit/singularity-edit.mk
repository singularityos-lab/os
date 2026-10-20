################################################################################
#
# singularity-edit
#
################################################################################

SINGULARITY_EDIT_VERSION = 75107e4d16d87a68a2de9683634e61f23606bca7
SINGULARITY_EDIT_SITE = $(call github,singularityos-lab,singularity-edit,$(SINGULARITY_EDIT_VERSION))
SINGULARITY_EDIT_LICENSE = GPL-3.0+
SINGULARITY_EDIT_LICENSE_FILES = LICENSE
SINGULARITY_EDIT_INSTALL_STAGING = YES
SINGULARITY_EDIT_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gtksourceview json-glib libsecret libsoup3 vte-gtk4 $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk)

SINGULARITY_EDIT_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
