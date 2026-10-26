################################################################################
#
# torchio
#
################################################################################

TORCHIO_VERSION = 625ed40ec2be07b043da760b52dfac02593cc3ee
TORCHIO_SITE = $(call github,singularityos-lab,torchio,$(TORCHIO_VERSION))
TORCHIO_LICENSE = GPL-3.0-or-later
TORCHIO_LICENSE_FILES = LICENSE
TORCHIO_GOMOD = github.com/singularityos-lab/torchio
TORCHIO_BUILD_TARGETS = cmd/torchio cmd/torchiod

define TORCHIO_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
TORCHIO_PRE_BUILD_HOOKS += TORCHIO_GO_VENDOR

define TORCHIO_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/torchio $(TARGET_DIR)/usr/bin/torchio
	$(INSTALL) -D -m 0755 $(@D)/bin/torchiod $(TARGET_DIR)/usr/bin/torchiod
	$(INSTALL) -D -m 0644 $(@D)/packaging/torchiod.desktop $(TARGET_DIR)/etc/xdg/autostart/torchiod.desktop
	$(INSTALL) -D -m 0644 $(@D)/data/usb-quirks.conf $(TARGET_DIR)/usr/share/torchio/usb-quirks.conf
	$(INSTALL) -D -m 0644 $(@D)/data/drivers/generic-pcl5.json $(TARGET_DIR)/usr/share/torchio/drivers/generic-pcl5.json
endef

define TORCHIO_DROP_CUPSD
	rm -f $(TARGET_DIR)/usr/sbin/cupsd $(TARGET_DIR)/usr/sbin/cupsfilter $(TARGET_DIR)/usr/bin/cupstestppd
	rm -rf $(TARGET_DIR)/usr/lib/cups $(TARGET_DIR)/usr/share/cups/doc-root $(TARGET_DIR)/usr/share/cups/templates
	rm -rf $(TARGET_DIR)/usr/share/cups/mime $(TARGET_DIR)/usr/share/cups/drv $(TARGET_DIR)/usr/share/cups/model
	rm -rf $(TARGET_DIR)/usr/share/cups/ppdc $(TARGET_DIR)/usr/share/cups/banners $(TARGET_DIR)/usr/share/cups/data
	rm -rf $(TARGET_DIR)/usr/share/cups/examples $(TARGET_DIR)/usr/share/cups/profiles $(TARGET_DIR)/usr/share/cups/usb
	rm -f $(TARGET_DIR)/etc/cups/cupsd.conf* $(TARGET_DIR)/etc/cups/cups-files.conf* $(TARGET_DIR)/etc/dbus-1/system.d/cups.conf
endef
TORCHIO_TARGET_FINALIZE_HOOKS += TORCHIO_DROP_CUPSD

$(eval $(golang-package))
