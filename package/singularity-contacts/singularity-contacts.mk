################################################################################
#
# singularity-contacts
#
################################################################################

SINGULARITY_CONTACTS_VERSION = 82ceb6b1e8dc1c77dd120a901966590d5c93443b
SINGULARITY_CONTACTS_SITE = $(call github,singularityos-lab,singularity-contacts,$(SINGULARITY_CONTACTS_VERSION))
SINGULARITY_CONTACTS_LICENSE = GPL-3.0+
SINGULARITY_CONTACTS_LICENSE_FILES = LICENSE
SINGULARITY_CONTACTS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_CONTACTS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
