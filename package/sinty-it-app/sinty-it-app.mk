################################################################################
#
# sinty-it-app
#
################################################################################

SINTY_IT_APP_VERSION = 41c72d01dddd95b686f132189538e027651b1197
SINTY_IT_APP_SITE = $(call github,singularityos-lab,sinty-it,$(SINTY_IT_APP_VERSION))
SINTY_IT_APP_DL_SUBDIR = sinty-it
SINTY_IT_APP_SUBDIR = app
SINTY_IT_APP_LICENSE = GPL-3.0-only
SINTY_IT_APP_LICENSE_FILES = LICENSE
SINTY_IT_APP_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsoup3

SINTY_IT_APP_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
