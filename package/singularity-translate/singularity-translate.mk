################################################################################
#
# singularity-translate
#
################################################################################

SINGULARITY_TRANSLATE_VERSION = 43f9ec7e15dd0bfea56c2fa1093b2cb9457da427
SINGULARITY_TRANSLATE_SITE = $(call github,singularityos-lab,singularity-translate,$(SINGULARITY_TRANSLATE_VERSION))
SINGULARITY_TRANSLATE_LICENSE = GPL-3.0+
SINGULARITY_TRANSLATE_LICENSE_FILES = LICENSE
SINGULARITY_TRANSLATE_INSTALL_STAGING = YES
SINGULARITY_TRANSLATE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libpeas2 libsecret libsoup3

SINGULARITY_TRANSLATE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
