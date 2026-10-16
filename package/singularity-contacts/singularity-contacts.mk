################################################################################
#
# singularity-contacts
#
################################################################################

SINGULARITY_CONTACTS_VERSION = d743e297f7525bbcb41bf3a39298fcb20e38c026
SINGULARITY_CONTACTS_SITE = $(call github,singularityos-lab,singularity-contacts,$(SINGULARITY_CONTACTS_VERSION))
SINGULARITY_CONTACTS_LICENSE = GPL-3.0+
SINGULARITY_CONTACTS_LICENSE_FILES = LICENSE
SINGULARITY_CONTACTS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_CONTACTS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
