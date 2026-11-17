################################################################################
#
# singularity-write
#
################################################################################

SINGULARITY_WRITE_VERSION = 91adf6329df6663f46b1e60220825c90594d1a22
SINGULARITY_WRITE_SITE = $(call github,singularityos-lab,singularity-write,$(SINGULARITY_WRITE_VERSION))
SINGULARITY_WRITE_LICENSE = GPL-3.0+
SINGULARITY_WRITE_LICENSE_FILES = LICENSE
SINGULARITY_WRITE_INSTALL_STAGING = YES
SINGULARITY_WRITE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk) gtksourceview poppler

SINGULARITY_WRITE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
