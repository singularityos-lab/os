################################################################################
#
# singularity-disks
#
################################################################################

SINGULARITY_DISKS_VERSION = a0928e0778c97a2dba075aa7e14fd54742fc0cb1
SINGULARITY_DISKS_SITE = $(call github,singularityos-lab,singularity-disks,$(SINGULARITY_DISKS_VERSION))
SINGULARITY_DISKS_LICENSE = GPL-3.0+
SINGULARITY_DISKS_LICENSE_FILES = LICENSE
SINGULARITY_DISKS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libpeas2

SINGULARITY_DISKS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_DISKS_DEPENDENCIES += host-iride
SINGULARITY_DISKS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
