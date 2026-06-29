################################################################################
#
# singularity-edit
#
################################################################################

SINGULARITY_EDIT_VERSION = aed3659af3d2375421f89f11ad14501d9390d28a
SINGULARITY_EDIT_SITE = $(call github,singularityos-lab,singularity-edit,$(SINGULARITY_EDIT_VERSION))
SINGULARITY_EDIT_LICENSE = GPL-3.0+
SINGULARITY_EDIT_LICENSE_FILES = LICENSE
SINGULARITY_EDIT_INSTALL_STAGING = YES
SINGULARITY_EDIT_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gtksourceview $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk)

SINGULARITY_EDIT_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
