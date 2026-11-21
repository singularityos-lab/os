################################################################################
#
# singularity-store
#
################################################################################

SINGULARITY_STORE_VERSION = cdcf745aafb284b217ee830a67875608141697f2
SINGULARITY_STORE_SITE = $(call github,singularityos-lab,singularity-store,$(SINGULARITY_STORE_VERSION))
SINGULARITY_STORE_LICENSE = GPL-3.0+
SINGULARITY_STORE_LICENSE_FILES = LICENSE
SINGULARITY_STORE_INSTALL_STAGING = YES
SINGULARITY_STORE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libsoup3 json-glib nettle

SINGULARITY_STORE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
