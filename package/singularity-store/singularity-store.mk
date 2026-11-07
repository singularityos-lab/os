################################################################################
#
# singularity-store
#
################################################################################

SINGULARITY_STORE_VERSION = 57796ff34e7d2a6d8970b193ca330d5bfe2e9ea8
SINGULARITY_STORE_SITE = $(call github,singularityos-lab,singularity-store,$(SINGULARITY_STORE_VERSION))
SINGULARITY_STORE_LICENSE = GPL-3.0+
SINGULARITY_STORE_LICENSE_FILES = LICENSE
SINGULARITY_STORE_INSTALL_STAGING = YES
SINGULARITY_STORE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libsoup3 json-glib nettle

SINGULARITY_STORE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
