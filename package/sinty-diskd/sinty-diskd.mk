################################################################################
#
# sinty-diskd
#
################################################################################

SINTY_DISKD_VERSION = 4913478145f332b8d98057ddd0d28d9cba951b06
SINTY_DISKD_SITE = $(call github,singularityos-lab,sinty-diskd,$(SINTY_DISKD_VERSION))
SINTY_DISKD_LICENSE = GPL-3.0-only
SINTY_DISKD_LICENSE_FILES = LICENSE
SINTY_DISKD_GOMOD = github.com/singularityos-lab/sinty-diskd
SINTY_DISKD_BUILD_TARGETS = cmd/sinty-diskd

define SINTY_DISKD_GO_VENDOR
	cd $(@D) && env -u GOFLAGS -u GOPROXY GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_DISKD_PRE_BUILD_HOOKS += SINTY_DISKD_GO_VENDOR

define SINTY_DISKD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-diskd $(TARGET_DIR)/usr/libexec/sinty-diskd
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-diskd.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-diskd.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-diskd.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/sinty-diskd.conf
	$(INSTALL) -D -m 0644 $(@D)/packaging/org.freedesktop.UDisks2.service $(TARGET_DIR)/usr/share/dbus-1/system-services/org.freedesktop.UDisks2.service
endef

$(eval $(golang-package))
