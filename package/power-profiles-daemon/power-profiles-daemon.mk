################################################################################
# power-profiles-daemon -- power profile switching over D-Bus
################################################################################
POWER_PROFILES_DAEMON_VERSION = 0.13
POWER_PROFILES_DAEMON_SITE = https://gitlab.freedesktop.org/upower/power-profiles-daemon/-/archive/$(POWER_PROFILES_DAEMON_VERSION)
POWER_PROFILES_DAEMON_SOURCE = power-profiles-daemon-$(POWER_PROFILES_DAEMON_VERSION).tar.bz2
POWER_PROFILES_DAEMON_LICENSE = GPL-3.0
POWER_PROFILES_DAEMON_LICENSE_FILES = COPYING
POWER_PROFILES_DAEMON_DEPENDENCIES = libglib2 libgudev polkit host-pkgconf
POWER_PROFILES_DAEMON_CONF_OPTS = \
	-Dgtk_doc=false \
	-Dpylint=false \
	-Dtests=false

$(eval $(meson-package))
