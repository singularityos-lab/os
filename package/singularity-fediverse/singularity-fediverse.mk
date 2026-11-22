################################################################################
#
# singularity-fediverse
#
################################################################################

SINGULARITY_FEDIVERSE_VERSION = 991eb2dee64cc15ed7f8a04885b5624361572381
SINGULARITY_FEDIVERSE_SITE = $(call github,singularityos-lab,singularity-fediverse,$(SINGULARITY_FEDIVERSE_VERSION))
SINGULARITY_FEDIVERSE_LICENSE = GPL-3.0+
SINGULARITY_FEDIVERSE_LICENSE_FILES = LICENSE
SINGULARITY_FEDIVERSE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libpeas2 libsecret libsoup3

SINGULARITY_FEDIVERSE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_FEDIVERSE_DEPENDENCIES += host-iride
SINGULARITY_FEDIVERSE_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
