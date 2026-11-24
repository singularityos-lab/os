################################################################################
#
# singularity-fediverse
#
################################################################################

SINGULARITY_FEDIVERSE_VERSION = 17423b6796f833d468e4a1d10f0fa62b386a0aad
SINGULARITY_FEDIVERSE_SITE = $(call github,singularityos-lab,singularity-fediverse,$(SINGULARITY_FEDIVERSE_VERSION))
SINGULARITY_FEDIVERSE_LICENSE = GPL-3.0+
SINGULARITY_FEDIVERSE_LICENSE_FILES = LICENSE
SINGULARITY_FEDIVERSE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libpeas2 libsecret libsoup3

SINGULARITY_FEDIVERSE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_FEDIVERSE_DEPENDENCIES += host-iride
SINGULARITY_FEDIVERSE_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
