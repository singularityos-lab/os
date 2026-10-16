################################################################################
#
# singularity-calendar
#
################################################################################

SINGULARITY_CALENDAR_VERSION = 26e1f18ebc18fcf9d25f86dc04288a4a1dddb004
SINGULARITY_CALENDAR_SITE = $(call github,singularityos-lab,singularity-calendar,$(SINGULARITY_CALENDAR_VERSION))
SINGULARITY_CALENDAR_LICENSE = GPL-3.0+
SINGULARITY_CALENDAR_LICENSE_FILES = LICENSE
SINGULARITY_CALENDAR_INSTALL_STAGING = YES
SINGULARITY_CALENDAR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gnome-online-accounts libsoup3 json-glib

SINGULARITY_CALENDAR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
