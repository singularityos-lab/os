################################################################################
#
# singularity-store
#
################################################################################

SINGULARITY_STORE_VERSION = 63738b3411b6c2a2b069fecb5096b82d898004c7
SINGULARITY_STORE_SITE = $(call github,singularityos-lab,singularity-store,$(SINGULARITY_STORE_VERSION))
SINGULARITY_STORE_LICENSE = GPL-3.0+
SINGULARITY_STORE_LICENSE_FILES = LICENSE
SINGULARITY_STORE_INSTALL_STAGING = YES
SINGULARITY_STORE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libsoup3 json-glib

SINGULARITY_STORE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
