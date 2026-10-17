################################################################################
#
# sinty-devd
#
################################################################################

SINTY_DEVD_VERSION = 9d383938556e35048dff373779b365f801eee8aa
SINTY_DEVD_SITE = $(call github,singularityos-lab,sinty-devd,$(SINTY_DEVD_VERSION))
SINTY_DEVD_LICENSE = GPL-3.0-only
SINTY_DEVD_LICENSE_FILES = LICENSE
SINTY_DEVD_GOMOD = github.com/singularityos-lab/sinty-devd
SINTY_DEVD_BUILD_TARGETS = cmd/sinty-devd cmd/sinty-devadm

define SINTY_DEVD_GO_VENDOR
	cd $(@D) && env -u GOFLAGS -u GOPROXY GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_DEVD_PRE_BUILD_HOOKS += SINTY_DEVD_GO_VENDOR

define SINTY_DEVD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-devd $(TARGET_DIR)/usr/libexec/sinty-devd
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-devadm $(TARGET_DIR)/usr/bin/sinty-devadm
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-devd.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-devd.service
endef

$(eval $(golang-package))
