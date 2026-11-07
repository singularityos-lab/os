################################################################################
#
# singularity-contacts
#
################################################################################

SINGULARITY_CONTACTS_VERSION = c2e9783db039535a9166aaf2fe96aaf8f310d0e4
SINGULARITY_CONTACTS_SITE = $(call github,singularityos-lab,singularity-contacts,$(SINGULARITY_CONTACTS_VERSION))
SINGULARITY_CONTACTS_LICENSE = GPL-3.0+
SINGULARITY_CONTACTS_LICENSE_FILES = LICENSE
SINGULARITY_CONTACTS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_CONTACTS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
