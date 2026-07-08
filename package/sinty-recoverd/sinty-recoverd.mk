################################################################################
#
# sinty-recoverd
#
################################################################################

SINTY_RECOVERD_VERSION = 1.0
SINTY_RECOVERD_SITE = $(BR2_EXTERNAL_SINGULARITY_PATH)/package/sinty-recoverd
SINTY_RECOVERD_SITE_METHOD = local
SINTY_RECOVERD_LICENSE = GPL-3.0+

define SINTY_RECOVERD_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		-o $(@D)/sinty-recoverd $(@D)/sinty-recoverd.c
endef

define SINTY_RECOVERD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/sinty-recoverd $(TARGET_DIR)/usr/libexec/sinty-recoverd
endef

$(eval $(generic-package))
