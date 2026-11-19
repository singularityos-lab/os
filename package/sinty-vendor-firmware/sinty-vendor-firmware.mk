################################################################################
#
# sinty-vendor-firmware
#
################################################################################

SINTY_VENDOR_FIRMWARE_VERSION = d056f43fa6a709818d115a020a545f2b686444fc
SINTY_VENDOR_FIRMWARE_SITE = $(call github,singularityos-lab,sinty-devices,$(SINTY_VENDOR_FIRMWARE_VERSION))
SINTY_VENDOR_FIRMWARE_LICENSE = GPL-3.0-or-later
SINTY_VENDOR_FIRMWARE_LICENSE_FILES = LICENSE
SINTY_VENDOR_FIRMWARE_GOMOD = github.com/singularityos-lab/sinty-devices
SINTY_VENDOR_FIRMWARE_GO_ENV = CGO_ENABLED=0
SINTY_VENDOR_FIRMWARE_BUILD_TARGETS = cmd/sinty-vendor-firmware

define SINTY_VENDOR_FIRMWARE_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_VENDOR_FIRMWARE_PRE_BUILD_HOOKS += SINTY_VENDOR_FIRMWARE_GO_VENDOR

define SINTY_VENDOR_FIRMWARE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-vendor-firmware $(TARGET_DIR)/usr/libexec/sinty-vendor-firmware
endef

$(eval $(golang-package))
