################################################################################
#
# singularity-machines
#
################################################################################

SINGULARITY_MACHINES_VERSION = 54f8ff21b362a0a2644b510a52ec4b3f04d26ca1
SINGULARITY_MACHINES_SITE = $(call github,singularityos-lab,singularity-machines,$(SINGULARITY_MACHINES_VERSION))
SINGULARITY_MACHINES_LICENSE = GPL-3.0+
SINGULARITY_MACHINES_LICENSE_FILES = LICENSE
SINGULARITY_MACHINES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib

SINGULARITY_MACHINES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
