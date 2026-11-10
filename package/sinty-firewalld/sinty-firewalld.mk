################################################################################
#
# sinty-firewalld
#
################################################################################

SINTY_FIREWALLD_VERSION = 232cce7033ecfcd789216c7a7af0f0d50465e2c1
SINTY_FIREWALLD_SITE = $(call github,singularityos-lab,sinty-firewalld,$(SINTY_FIREWALLD_VERSION))
SINTY_FIREWALLD_LICENSE = GPL-3.0-only
SINTY_FIREWALLD_LICENSE_FILES = LICENSE
SINTY_FIREWALLD_GOMOD = github.com/singularityos-lab/sinty-firewalld
SINTY_FIREWALLD_BUILD_TARGETS = cmd/sinty-firewalld
SINTY_FIREWALLD_DEPENDENCIES = host-pkgconf libsingularity

define SINTY_FIREWALLD_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_FIREWALLD_PRE_BUILD_HOOKS += SINTY_FIREWALLD_GO_VENDOR

define SINTY_FIREWALLD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-firewalld $(TARGET_DIR)/usr/libexec/sinty-firewalld
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-firewalld.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-firewalld.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-firewalld.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/sinty-firewalld.conf
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.Firewall1.service $(TARGET_DIR)/usr/share/dbus-1/system-services/dev.sinty.Firewall1.service
endef

$(eval $(golang-package))
