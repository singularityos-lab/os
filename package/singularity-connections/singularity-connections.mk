################################################################################
#
# singularity-connections
#
################################################################################

SINGULARITY_CONNECTIONS_VERSION = 4431c7ab44ab6c194eacc0ceefb953be61fe376d
SINGULARITY_CONNECTIONS_SITE = $(call github,singularityos-lab,singularity-connections,$(SINGULARITY_CONNECTIONS_VERSION))
SINGULARITY_CONNECTIONS_LICENSE = GPL-3.0+
SINGULARITY_CONNECTIONS_LICENSE_FILES = LICENSE
SINGULARITY_CONNECTIONS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsecret
SINGULARITY_CONNECTIONS_CONF_OPTS = -Drdp=disabled

SINGULARITY_CONNECTIONS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_CONNECTIONS_DEPENDENCIES += host-iride
SINGULARITY_CONNECTIONS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
