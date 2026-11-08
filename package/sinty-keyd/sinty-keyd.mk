################################################################################
#
# sinty-keyd
#
################################################################################

SINTY_KEYD_VERSION = 7c9dd0cf2ed0a6d9ae0af77e7a26bd7be4bbb7ec
SINTY_KEYD_SITE = $(call github,singularityos-lab,sinty-keyd,$(SINTY_KEYD_VERSION))
SINTY_KEYD_LICENSE = GPL-3.0-only
SINTY_KEYD_LICENSE_FILES = LICENSE
SINTY_KEYD_GOMOD = github.com/singularityos-lab/sinty-keyd
SINTY_KEYD_BUILD_TARGETS = cmd/sinty-keyd
SINTY_KEYD_DEPENDENCIES = sinty-crypto

define SINTY_KEYD_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_KEYD_PRE_BUILD_HOOKS += SINTY_KEYD_GO_VENDOR

define SINTY_KEYD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-keyd $(TARGET_DIR)/usr/libexec/sinty-keyd
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-keyd.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-keyd.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-keyd.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/sinty-keyd.conf
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.Key1.service $(TARGET_DIR)/usr/share/dbus-1/system-services/dev.sinty.Key1.service
endef

$(eval $(golang-package))
