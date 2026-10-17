################################################################################
#
# sinty-locale
#
################################################################################

SINTY_LOCALE_VERSION = 113bda948a3584b9fd855d59954e3ab10186b35b
SINTY_LOCALE_SITE = $(call github,singularityos-lab,sinty-locale,$(SINTY_LOCALE_VERSION))
SINTY_LOCALE_LICENSE = GPL-3.0-only
SINTY_LOCALE_LICENSE_FILES = LICENSE
SINTY_LOCALE_GOMOD = github.com/singularityos-lab/sinty-locale
SINTY_LOCALE_BUILD_TARGETS = cmd/sinty-locale cmd/sinty-localed

define SINTY_LOCALE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-locale $(TARGET_DIR)/usr/bin/sinty-locale
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-localed $(TARGET_DIR)/usr/libexec/sinty-localed
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-localed.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-localed.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/org.freedesktop.locale1.service $(TARGET_DIR)/usr/share/dbus-1/system-services/org.freedesktop.locale1.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/org.freedesktop.locale1.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/org.freedesktop.locale1.conf
endef

$(eval $(golang-package))
