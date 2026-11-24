################################################################################
#
# singularity-calendar
#
################################################################################

SINGULARITY_CALENDAR_VERSION = 9bdf0f9561176b5750f4f45d219893b3d05fa870
SINGULARITY_CALENDAR_SITE = $(call github,singularityos-lab,singularity-calendar,$(SINGULARITY_CALENDAR_VERSION))
SINGULARITY_CALENDAR_LICENSE = GPL-3.0+
SINGULARITY_CALENDAR_LICENSE_FILES = LICENSE
SINGULARITY_CALENDAR_INSTALL_STAGING = YES
SINGULARITY_CALENDAR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gnome-online-accounts libsoup3 json-glib

SINGULARITY_CALENDAR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_CALENDAR_DEPENDENCIES += host-iride
SINGULARITY_CALENDAR_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
