################################################################################
# power-profiles-daemon -- power profile switching over D-Bus
################################################################################
POWER_PROFILES_DAEMON_VERSION = 0.13
POWER_PROFILES_DAEMON_SITE = https://gitlab.freedesktop.org/upower/power-profiles-daemon/-/archive/$(POWER_PROFILES_DAEMON_VERSION)
POWER_PROFILES_DAEMON_SOURCE = power-profiles-daemon-$(POWER_PROFILES_DAEMON_VERSION).tar.bz2
POWER_PROFILES_DAEMON_LICENSE = GPL-3.0
POWER_PROFILES_DAEMON_LICENSE_FILES = COPYING
POWER_PROFILES_DAEMON_DEPENDENCIES = libglib2 libgudev polkit host-pkgconf
# systemdsystemunitdir defaults to 'auto', which makes meson resolve the unit directory
# through dependency('systemd'). That is a hard failure here, since this config builds no
# systemd (BR2_INIT_NONE) and ships no systemd.pc. Name the directory the other packages
# install their units into and the lookup is skipped.
POWER_PROFILES_DAEMON_CONF_OPTS = \
	-Dsystemdsystemunitdir=/usr/lib/systemd/system \
	-Dgtk_doc=false \
	-Dpylint=false \
	-Dtests=false

$(eval $(meson-package))
