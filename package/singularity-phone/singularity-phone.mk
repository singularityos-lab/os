################################################################################
#
# singularity-phone
#
################################################################################

SINGULARITY_PHONE_VERSION = ae3910d70bfdad3758d7e3006f9edb53a8f9afca
SINGULARITY_PHONE_SITE = $(call github,singularityos-lab,singularity-phone,$(SINGULARITY_PHONE_VERSION))
SINGULARITY_PHONE_LICENSE = GPL-3.0+
SINGULARITY_PHONE_LICENSE_FILES = LICENSE
SINGULARITY_PHONE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib

SINGULARITY_PHONE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_PHONE_DEPENDENCIES += host-iride
SINGULARITY_PHONE_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
