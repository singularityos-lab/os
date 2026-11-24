################################################################################
#
# singularity-machines
#
################################################################################

SINGULARITY_MACHINES_VERSION = a99ce4b9ef46d2819d218cc724020b9c30604d10
SINGULARITY_MACHINES_SITE = $(call github,singularityos-lab,singularity-machines,$(SINGULARITY_MACHINES_VERSION))
SINGULARITY_MACHINES_LICENSE = GPL-3.0+
SINGULARITY_MACHINES_LICENSE_FILES = LICENSE
SINGULARITY_MACHINES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib

SINGULARITY_MACHINES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_MACHINES_DEPENDENCIES += host-iride
SINGULARITY_MACHINES_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
