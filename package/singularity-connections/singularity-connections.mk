################################################################################
#
# singularity-connections
#
################################################################################

SINGULARITY_CONNECTIONS_VERSION = 6b82325d67a0798c617aa113e429fd3443064f73
SINGULARITY_CONNECTIONS_SITE = $(call github,singularityos-lab,singularity-connections,$(SINGULARITY_CONNECTIONS_VERSION))
SINGULARITY_CONNECTIONS_LICENSE = GPL-3.0+
SINGULARITY_CONNECTIONS_LICENSE_FILES = LICENSE
SINGULARITY_CONNECTIONS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsecret
SINGULARITY_CONNECTIONS_CONF_OPTS = -Drdp=disabled

SINGULARITY_CONNECTIONS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
