################################################################################
#
# gamemode
#
################################################################################

GAMEMODE_VERSION = 1.8.2
GAMEMODE_SITE = https://github.com/FeralInteractive/gamemode/releases/download/$(GAMEMODE_VERSION)
GAMEMODE_SOURCE = gamemode-$(GAMEMODE_VERSION).tar.xz
GAMEMODE_LICENSE = BSD-3-Clause
GAMEMODE_LICENSE_FILES = LICENSE.txt
GAMEMODE_INSTALL_STAGING = YES
GAMEMODE_DEPENDENCIES = host-pkgconf basu dbus inih
GAMEMODE_CONF_OPTS = \
	-Dwith-sd-bus-provider=basu \
	-Dwith-dbus-service-dir=/usr/share/dbus-1/services \
	-Dwith-pam-renicing=false \
	-Dwith-examples=false \
	-Dwith-util=true

$(eval $(meson-package))
