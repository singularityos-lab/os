################################################################################
#
# singularity-contacts
#
################################################################################

SINGULARITY_CONTACTS_VERSION = a66cb59be6ca320bc78e2d8c7bb1f3d7d62e90b1
SINGULARITY_CONTACTS_SITE = $(call github,singularityos-lab,singularity-contacts,$(SINGULARITY_CONTACTS_VERSION))
SINGULARITY_CONTACTS_LICENSE = GPL-3.0+
SINGULARITY_CONTACTS_LICENSE_FILES = LICENSE
SINGULARITY_CONTACTS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_CONTACTS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_CONTACTS_DEPENDENCIES += host-iride
SINGULARITY_CONTACTS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
