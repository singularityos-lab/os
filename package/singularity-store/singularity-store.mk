################################################################################
#
# singularity-store
#
################################################################################

SINGULARITY_STORE_VERSION = d327404537f7510d5691dba8016b7643931b45f5
SINGULARITY_STORE_SITE = $(call github,singularityos-lab,singularity-store,$(SINGULARITY_STORE_VERSION))
SINGULARITY_STORE_LICENSE = GPL-3.0+
SINGULARITY_STORE_LICENSE_FILES = LICENSE
SINGULARITY_STORE_INSTALL_STAGING = YES
SINGULARITY_STORE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libsoup3 json-glib

SINGULARITY_STORE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
