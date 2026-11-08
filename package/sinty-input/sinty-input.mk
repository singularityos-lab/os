################################################################################
#
# sinty-input
#
################################################################################

SINTY_INPUT_VERSION = 8e0911324da88624640923ee4386412bb91a730d
SINTY_INPUT_SITE = $(call github,singularityos-lab,sinty-input,$(SINTY_INPUT_VERSION))
SINTY_INPUT_LICENSE = GPL-3.0-only, GPL-2.0+ (Japanese dictionary), CC-BY-SA-4.0 (Chinese dictionary)
SINTY_INPUT_LICENSE_FILES = LICENSE internal/dict/data/NOTICE
SINTY_INPUT_GOMOD = github.com/singularityos-lab/sinty-input
SINTY_INPUT_BUILD_TARGETS = cmd/sinty-input

define SINTY_INPUT_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_INPUT_PRE_BUILD_HOOKS += SINTY_INPUT_GO_VENDOR

define SINTY_INPUT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-input $(TARGET_DIR)/usr/libexec/sinty-input
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.Input1.service $(TARGET_DIR)/usr/share/dbus-1/services/dev.sinty.Input1.service
endef

$(eval $(golang-package))
