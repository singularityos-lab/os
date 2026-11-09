################################################################################
#
# singularity-machines
#
################################################################################

SINGULARITY_MACHINES_VERSION = 8f1926d850ddc03e2983c998cd0bda3c4a63ca0c
SINGULARITY_MACHINES_SITE = $(call github,singularityos-lab,singularity-machines,$(SINGULARITY_MACHINES_VERSION))
SINGULARITY_MACHINES_LICENSE = GPL-3.0+
SINGULARITY_MACHINES_LICENSE_FILES = LICENSE
SINGULARITY_MACHINES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib

SINGULARITY_MACHINES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
