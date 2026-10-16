################################################################################
#
# singularity-write
#
################################################################################

SINGULARITY_WRITE_VERSION = 9d710cea564dfe3dce092338c2bd182f1c089e6b
SINGULARITY_WRITE_SITE = $(call github,singularityos-lab,singularity-write,$(SINGULARITY_WRITE_VERSION))
SINGULARITY_WRITE_LICENSE = GPL-3.0+
SINGULARITY_WRITE_LICENSE_FILES = LICENSE
SINGULARITY_WRITE_INSTALL_STAGING = YES
SINGULARITY_WRITE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk) gtksourceview poppler

SINGULARITY_WRITE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
