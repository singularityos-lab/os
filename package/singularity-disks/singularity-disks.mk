################################################################################
#
# singularity-disks
#
################################################################################

SINGULARITY_DISKS_VERSION = d4826f39356f55f677f95efa712fde161945814e
SINGULARITY_DISKS_SITE = $(call github,singularityos-lab,singularity-disks,$(SINGULARITY_DISKS_VERSION))
SINGULARITY_DISKS_LICENSE = GPL-3.0+
SINGULARITY_DISKS_LICENSE_FILES = LICENSE
SINGULARITY_DISKS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libpeas2

SINGULARITY_DISKS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_DISKS_DEPENDENCIES += host-iride
SINGULARITY_DISKS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
