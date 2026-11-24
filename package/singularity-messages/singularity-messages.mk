################################################################################
#
# singularity-messages
#
################################################################################

SINGULARITY_MESSAGES_VERSION = 057e66693b3f442a011e00e269188fb351a7e2e6
SINGULARITY_MESSAGES_SITE = $(call github,singularityos-lab,singularity-messages,$(SINGULARITY_MESSAGES_VERSION))
SINGULARITY_MESSAGES_LICENSE = GPL-3.0+
SINGULARITY_MESSAGES_LICENSE_FILES = LICENSE
SINGULARITY_MESSAGES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsoup3 libpeas2

SINGULARITY_MESSAGES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_MESSAGES_DEPENDENCIES += host-iride
SINGULARITY_MESSAGES_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
