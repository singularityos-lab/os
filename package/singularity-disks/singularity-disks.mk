################################################################################
#
# singularity-disks
#
################################################################################

SINGULARITY_DISKS_VERSION = 944190f16554d1edeeb6fbb79af40b425fe547d5
SINGULARITY_DISKS_SITE = $(call github,singularityos-lab,singularity-disks,$(SINGULARITY_DISKS_VERSION))
SINGULARITY_DISKS_LICENSE = GPL-3.0+
SINGULARITY_DISKS_LICENSE_FILES = LICENSE
SINGULARITY_DISKS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libpeas2

SINGULARITY_DISKS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
