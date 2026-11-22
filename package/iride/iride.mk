################################################################################
#
# iride
#
################################################################################

IRIDE_VERSION = 34dd7a28b81bca521a86eaeddfcd1199e1ed1e8f
IRIDE_SITE = $(call github,singularityos-lab,iride,$(IRIDE_VERSION))
IRIDE_LICENSE = GPL-3.0-only
IRIDE_LICENSE_FILES = LICENSE
IRIDE_INSTALL_STAGING = YES
IRIDE_DEPENDENCIES = host-zig

IRIDE_GLIBC = $(firstword $(subst -, ,$(GLIBC_VERSION)))

define IRIDE_BUILD_CMDS
	cd $(@D) && $(TARGET_MAKE_ENV) $(HOST_DIR)/bin/zig build -Dtool=false -Doptimize=ReleaseSafe \
		-Dtarget=$(call qstrip,$(BR2_ARCH))-linux-gnu$(if $(IRIDE_GLIBC),.$(IRIDE_GLIBC)) \
		-Dcpu=baseline \
		--prefix $(@D)/out
endef

define IRIDE_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0644 $(@D)/out/include/libiride.h $(STAGING_DIR)/usr/include/libiride.h
	$(INSTALL) -D -m 0755 $(@D)/out/lib/libiride.so $(STAGING_DIR)/usr/lib/libiride.so
	$(INSTALL) -D -m 0644 $(@D)/out/share/vala/vapi/libiride.vapi $(STAGING_DIR)/usr/share/vala/vapi/libiride.vapi
endef

define IRIDE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/out/lib/libiride.so $(TARGET_DIR)/usr/lib/libiride.so
endef

$(eval $(generic-package))
