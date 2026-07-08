################################################################################
# libsystemd-shim
################################################################################
LIBSYSTEMD_SHIM_VERSION = 1.0
LIBSYSTEMD_SHIM_SITE_METHOD = local
LIBSYSTEMD_SHIM_SITE = $(BR2_EXTERNAL_SINGULARITY_PATH)/package/libsystemd-shim/src
LIBSYSTEMD_SHIM_LICENSE = GPL-3.0-or-later
LIBSYSTEMD_SHIM_INSTALL_STAGING = YES
# Make buildroot treat this as the libsystemd provider. Consumers must depend on
# 'libsystemd-shim' (repoint their _DEPENDENCIES from 'systemd'); see NOTES.

define LIBSYSTEMD_SHIM_BUILD_CMDS
	$(TARGET_CC) -shared -fPIC -O2 -Wall \
		-Wl,--version-script=$(@D)/libsystemd.map \
		-Wl,-soname,libsystemd.so.0 \
		-o $(@D)/libsystemd.so.0 $(@D)/libsystemd_shim.c
endef

define LIBSYSTEMD_SHIM_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0755 $(@D)/libsystemd.so.0 $(STAGING_DIR)/usr/lib/libsystemd.so.0
	ln -sf libsystemd.so.0 $(STAGING_DIR)/usr/lib/libsystemd.so
	$(INSTALL) -D -m 0644 $(@D)/libsystemd.pc $(STAGING_DIR)/usr/lib/pkgconfig/libsystemd.pc
	mkdir -p $(STAGING_DIR)/usr/include/systemd
	cp -a $(@D)/include/systemd/*.h $(STAGING_DIR)/usr/include/systemd/
endef

define LIBSYSTEMD_SHIM_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/libsystemd.so.0 $(TARGET_DIR)/usr/lib/libsystemd.so.0
	ln -sf libsystemd.so.0 $(TARGET_DIR)/usr/lib/libsystemd.so
endef

$(eval $(generic-package))
