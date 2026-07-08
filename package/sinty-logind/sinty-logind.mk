################################################################################
# sinty-logind -- login1 shim for sinit (power actions)
################################################################################
SINTY_LOGIND_VERSION = 1.0
SINTY_LOGIND_SITE = $(BR2_EXTERNAL_SINGULARITY_PATH)/package/sinty-logind
SINTY_LOGIND_SITE_METHOD = local
SINTY_LOGIND_LICENSE = GPL-3.0+
SINTY_LOGIND_DEPENDENCIES = libglib2

define SINTY_LOGIND_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) `$(HOST_DIR)/bin/pkg-config --cflags gio-2.0` \
		-o $(@D)/sinty-logind $(@D)/sinty-logind.c \
		`$(HOST_DIR)/bin/pkg-config --libs gio-2.0` $(TARGET_LDFLAGS)
endef

define SINTY_LOGIND_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/sinty-logind $(TARGET_DIR)/usr/libexec/sinty-logind
endef

$(eval $(generic-package))
