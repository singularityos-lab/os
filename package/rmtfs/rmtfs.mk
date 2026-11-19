################################################################################
#
# rmtfs
#
################################################################################

RMTFS_VERSION = b30a3eb38f9af283f18dbd3c7755653efc52c094
RMTFS_SITE = $(call github,linux-msm,rmtfs,$(RMTFS_VERSION))
RMTFS_LICENSE = BSD-3-Clause
RMTFS_LICENSE_FILES = LICENSE
RMTFS_DEPENDENCIES = qrtr udev

define RMTFS_BUILD_CMDS
	touch $(@D)/qmi_rmtfs.c $(@D)/qmi_rmtfs.h
	$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) rmtfs
endef

define RMTFS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/rmtfs $(TARGET_DIR)/usr/bin/rmtfs
	$(INSTALL) -D -m 0644 $(RMTFS_PKGDIR)/rmtfs.service \
		$(TARGET_DIR)/usr/lib/systemd/system/rmtfs.service
	mkdir -p $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants
	ln -sf /usr/lib/systemd/system/rmtfs.service \
		$(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/rmtfs.service
endef

$(eval $(generic-package))
