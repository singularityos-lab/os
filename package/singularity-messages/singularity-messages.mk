################################################################################
#
# singularity-messages
#
################################################################################

SINGULARITY_MESSAGES_VERSION = f675036d83208bea4c07144612622dfe1bcec2e4
SINGULARITY_MESSAGES_SITE = $(call github,singularityos-lab,singularity-messages,$(SINGULARITY_MESSAGES_VERSION))
SINGULARITY_MESSAGES_LICENSE = GPL-3.0+
SINGULARITY_MESSAGES_LICENSE_FILES = LICENSE
SINGULARITY_MESSAGES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsoup3 libpeas2

SINGULARITY_MESSAGES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
