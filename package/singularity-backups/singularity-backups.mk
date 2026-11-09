################################################################################
#
# singularity-backups
#
################################################################################

SINGULARITY_BACKUPS_VERSION = 34c361d955b89e2145f217a7abbc540878979870
SINGULARITY_BACKUPS_SITE = $(call github,singularityos-lab,singularity-backups,$(SINGULARITY_BACKUPS_VERSION))
SINGULARITY_BACKUPS_LICENSE = GPL-3.0+
SINGULARITY_BACKUPS_LICENSE_FILES = LICENSE
SINGULARITY_BACKUPS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libpeas2 libsecret

SINGULARITY_BACKUPS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
