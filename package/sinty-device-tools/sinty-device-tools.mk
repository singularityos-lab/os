################################################################################
#
# sinty-device-tools
#
################################################################################

SINTY_DEVICE_TOOLS_VERSION = 84a88920c0c4f85287654e71dc46e57d16f65bbc
SINTY_DEVICE_TOOLS_SITE = $(call github,singularityos-lab,sinty-devices,$(SINTY_DEVICE_TOOLS_VERSION))
SINTY_DEVICE_TOOLS_LICENSE = GPL-3.0-or-later
SINTY_DEVICE_TOOLS_LICENSE_FILES = LICENSE
SINTY_DEVICE_TOOLS_GOMOD = github.com/singularityos-lab/sinty-devices
SINTY_DEVICE_TOOLS_GO_ENV = CGO_ENABLED=0
SINTY_DEVICE_TOOLS_BUILD_TARGETS = cmd/sinty-vendor-firmware cmd/sinty-android-boot cmd/sinty-usb-link

define SINTY_DEVICE_TOOLS_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_DEVICE_TOOLS_PRE_BUILD_HOOKS += SINTY_DEVICE_TOOLS_GO_VENDOR

define SINTY_DEVICE_TOOLS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-vendor-firmware $(TARGET_DIR)/usr/libexec/sinty-vendor-firmware
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-android-boot $(TARGET_DIR)/usr/libexec/sinty-android-boot
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-usb-link $(TARGET_DIR)/usr/libexec/sinty-usb-link
	$(INSTALL) -D -m 0644 $(SINTY_DEVICE_TOOLS_PKGDIR)/sinty-usb-link.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-usb-link.service
	mkdir -p $(TARGET_DIR)/usr/lib/atomloops/kernel.d
	ln -sf ../../../libexec/sinty-android-boot $(TARGET_DIR)/usr/lib/atomloops/kernel.d/50-android-boot
endef

$(eval $(golang-package))
