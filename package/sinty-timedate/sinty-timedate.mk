################################################################################
#
# sinty-timedate
#
################################################################################

SINTY_TIMEDATE_VERSION = c1cff0f9c6a2778487085bb916691c69e8632068
SINTY_TIMEDATE_SITE = $(call github,singularityos-lab,sinty-timedate,$(SINTY_TIMEDATE_VERSION))
SINTY_TIMEDATE_LICENSE = MIT
SINTY_TIMEDATE_LICENSE_FILES = LICENSE
SINTY_TIMEDATE_GOMOD = github.com/singularityos-lab/sinty-timedate
SINTY_TIMEDATE_BUILD_TARGETS = cmd/sinty-timedate cmd/sinty-timedated

define SINTY_TIMEDATE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-timedate $(TARGET_DIR)/usr/bin/sinty-timedate
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-timedated $(TARGET_DIR)/usr/libexec/sinty-timedated
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-timedated.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-timedated.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/org.freedesktop.timedate1.service $(TARGET_DIR)/usr/share/dbus-1/system-services/org.freedesktop.timedate1.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/org.freedesktop.timedate1.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/org.freedesktop.timedate1.conf
endef

$(eval $(golang-package))
