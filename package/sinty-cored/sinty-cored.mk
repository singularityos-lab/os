################################################################################
#
# sinty-cored
#
################################################################################

SINTY_CORED_VERSION = 1365a60334e0f4793d7976b08f6e8ebfe0447842
SINTY_CORED_SITE = $(call github,singularityos-lab,sinty-cored,$(SINTY_CORED_VERSION))
SINTY_CORED_LICENSE = GPL-3.0-only
SINTY_CORED_LICENSE_FILES = LICENSE
SINTY_CORED_GOMOD = github.com/singularityos-lab/sinty-cored
SINTY_CORED_BUILD_TARGETS = cmd/sinty-cored cmd/sinty-screen
SINTY_CORED_DEPENDENCIES = sinty-keyd

define SINTY_CORED_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_CORED_PRE_BUILD_HOOKS += SINTY_CORED_GO_VENDOR

define SINTY_CORED_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-cored $(TARGET_DIR)/usr/libexec/sinty-cored
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-screen $(TARGET_DIR)/usr/bin/sinty-screen
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-cored.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-cored.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-screen.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-screen.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-cored.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/sinty-cored.conf
endef

$(eval $(golang-package))
