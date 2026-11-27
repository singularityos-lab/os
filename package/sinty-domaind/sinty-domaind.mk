################################################################################
#
# sinty-domaind
#
################################################################################

SINTY_DOMAIND_VERSION = 16f123ac72d2f678b9111e6d0f12e24ae2624b31
SINTY_DOMAIND_SITE = $(call github,singularityos-lab,sinty-domaind,$(SINTY_DOMAIND_VERSION))
SINTY_DOMAIND_LICENSE = GPL-3.0-only
SINTY_DOMAIND_LICENSE_FILES = LICENSE
SINTY_DOMAIND_GOMOD = github.com/singularityos-lab/sinty-domaind
SINTY_DOMAIND_BUILD_TARGETS = cmd/sinty-domaind cmd/sinty-domain

define SINTY_DOMAIND_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_DOMAIND_PRE_BUILD_HOOKS += SINTY_DOMAIND_GO_VENDOR

define SINTY_DOMAIND_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-domaind $(TARGET_DIR)/usr/libexec/sinty-domaind
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-domain $(TARGET_DIR)/usr/bin/sinty-domain
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-domaind.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-domaind.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-domaind.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/sinty-domaind.conf
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.Domain1.service $(TARGET_DIR)/usr/share/dbus-1/system-services/dev.sinty.Domain1.service
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants
	ln -sf ../sinty-domaind.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/sinty-domaind.service
endef

$(eval $(golang-package))
