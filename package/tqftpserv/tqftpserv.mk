################################################################################
#
# tqftpserv
#
################################################################################

TQFTPSERV_VERSION = eb4b9a04ff92d2753ededf32cc3b6ed287f6e29b
TQFTPSERV_SITE = $(call github,linux-msm,tqftpserv,$(TQFTPSERV_VERSION))
TQFTPSERV_LICENSE = BSD-3-Clause
TQFTPSERV_LICENSE_FILES = LICENSE
TQFTPSERV_DEPENDENCIES = host-pkgconf qrtr

ifeq ($(BR2_PACKAGE_ZSTD),y)
TQFTPSERV_DEPENDENCIES += zstd
endif
ifeq ($(BR2_PACKAGE_XZ),y)
TQFTPSERV_DEPENDENCIES += xz
endif

define TQFTPSERV_INSTALL_SERVICE
	rm -f $(TARGET_DIR)/usr/lib/systemd/system/tqftpserv.service \
		$(TARGET_DIR)/usr/lib/systemd/system/tqftpserv-populate-readwrite.service
	$(INSTALL) -D -m 0644 $(TQFTPSERV_PKGDIR)/tqftpserv.service \
		$(TARGET_DIR)/usr/lib/systemd/system/tqftpserv.service
	mkdir -p $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants
	ln -sf /usr/lib/systemd/system/tqftpserv.service \
		$(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/tqftpserv.service
endef
TQFTPSERV_POST_INSTALL_TARGET_HOOKS += TQFTPSERV_INSTALL_SERVICE

$(eval $(meson-package))
