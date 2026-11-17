################################################################################
#
# singularity-disks
#
################################################################################

SINGULARITY_DISKS_VERSION = 77d58c1cad7494649b1f94335abd22226be2f93f
SINGULARITY_DISKS_SITE = $(call github,singularityos-lab,singularity-disks,$(SINGULARITY_DISKS_VERSION))
SINGULARITY_DISKS_LICENSE = GPL-3.0+
SINGULARITY_DISKS_LICENSE_FILES = LICENSE
SINGULARITY_DISKS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libpeas2

SINGULARITY_DISKS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
