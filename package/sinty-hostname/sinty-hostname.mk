################################################################################
#
# sinty-hostname
#
################################################################################

SINTY_HOSTNAME_VERSION = d2cb309460d975cc0b2abff954166a29287e6b34
SINTY_HOSTNAME_SITE = $(call github,singularityos-lab,sinty-hostname,$(SINTY_HOSTNAME_VERSION))
SINTY_HOSTNAME_LICENSE = GPL-3.0-only
SINTY_HOSTNAME_LICENSE_FILES = LICENSE
SINTY_HOSTNAME_GOMOD = github.com/singularityos-lab/sinty-hostname
SINTY_HOSTNAME_BUILD_TARGETS = cmd/sinty-hostname cmd/sinty-hostnamed

define SINTY_HOSTNAME_GO_VENDOR
	cd $(@D) && env -u GOFLAGS -u GOPROXY GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_HOSTNAME_PRE_BUILD_HOOKS += SINTY_HOSTNAME_GO_VENDOR

define SINTY_HOSTNAME_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-hostname $(TARGET_DIR)/usr/bin/sinty-hostname
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-hostnamed $(TARGET_DIR)/usr/libexec/sinty-hostnamed
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-hostnamed.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-hostnamed.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/org.freedesktop.hostname1.service $(TARGET_DIR)/usr/share/dbus-1/system-services/org.freedesktop.hostname1.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/org.freedesktop.hostname1.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/org.freedesktop.hostname1.conf
endef

$(eval $(golang-package))
