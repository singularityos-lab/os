################################################################################
#
# iride
#
################################################################################

IRIDE_VERSION = a56eea6709c724b7db32ade658eb7f32913a98a5
IRIDE_SITE = $(call github,singularityos-lab,iride,$(IRIDE_VERSION))
IRIDE_LICENSE = GPL-3.0-only
IRIDE_LICENSE_FILES = LICENSE
IRIDE_INSTALL_STAGING = YES
IRIDE_DEPENDENCIES = gdk-pixbuf host-iride host-pkgconf host-zig libglib2
IRIDE_LOADERS_DIR = lib/gdk-pixbuf-2.0/2.10.0/loaders

IRIDE_GLIBC = $(firstword $(subst -, ,$(GLIBC_VERSION)))

define IRIDE_BUILD_CMDS
	cd $(@D) && $(TARGET_MAKE_ENV) PKG_CONFIG=$(PKG_CONFIG_HOST_BINARY) $(HOST_DIR)/bin/zig build \
		-Dtool=false -Dpixbuf=true -Doptimize=ReleaseSafe \
		-Dtarget=$(call qstrip,$(BR2_ARCH))-linux-gnu$(if $(IRIDE_GLIBC),.$(IRIDE_GLIBC)) \
		-Dcpu=baseline \
		--search-prefix $(STAGING_DIR)/usr \
		--prefix $(@D)/out
endef

define IRIDE_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0644 $(@D)/out/include/libiride.h $(STAGING_DIR)/usr/include/libiride.h
	$(INSTALL) -D -m 0755 $(@D)/out/lib/libiride.so $(STAGING_DIR)/usr/lib/libiride.so
	$(INSTALL) -D -m 0644 $(@D)/out/share/vala/vapi/libiride.vapi $(STAGING_DIR)/usr/share/vala/vapi/libiride.vapi
endef

define IRIDE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/out/lib/libiride.so $(TARGET_DIR)/usr/lib/libiride.so
	$(INSTALL) -D -m 0755 $(@D)/out/$(IRIDE_LOADERS_DIR)/libpixbufloader-iride.so \
		$(TARGET_DIR)/usr/$(IRIDE_LOADERS_DIR)/libpixbufloader-iride.so
	$(INSTALL) -D -m 0644 $(@D)/out/share/mime/packages/dev.sinty.iride.xml \
		$(TARGET_DIR)/usr/share/mime/packages/dev.sinty.iride.xml
endef

HOST_IRIDE_DEPENDENCIES = host-cairo host-gdk-pixbuf host-libglib2 host-pkgconf host-sit host-zig

define HOST_IRIDE_BUILD_CMDS
	cd $(@D) && $(HOST_MAKE_ENV) PKG_CONFIG=$(PKG_CONFIG_HOST_BINARY) $(HOST_DIR)/bin/zig build \
		-Dpixbuf=true -Doptimize=ReleaseSafe \
		-Dcpu=baseline \
		--search-prefix $(HOST_DIR) \
		--prefix $(@D)/out
endef

define HOST_IRIDE_INSTALL_CMDS
	$(INSTALL) -D -m 0755 $(@D)/out/bin/iride $(HOST_DIR)/bin/iride
	$(INSTALL) -D -m 0755 $(@D)/out/$(IRIDE_LOADERS_DIR)/libpixbufloader-iride.so \
		$(HOST_DIR)/$(IRIDE_LOADERS_DIR)/libpixbufloader-iride.so
endef

$(eval $(generic-package))
$(eval $(host-generic-package))
