################################################################################
#
# cpak-prebuilt
#
################################################################################

CPAK_PREBUILT_VERSION = 2.14.18-managed
CPAK_PREBUILT_SOURCE = cpak-$(CPAK_PREBUILT_VERSION)-x86_64.tar.zst
CPAK_PREBUILT_SITE = https://github.com/singularityos-lab/os/releases/download/prebuilt-26A131
CPAK_PREBUILT_LICENSE = LGPL-2.1

define CPAK_PREBUILT_INSTALL_TARGET_CMDS
	cp -a $(@D)/etc/. $(TARGET_DIR)/etc/
	cp -a $(@D)/usr/. $(TARGET_DIR)/usr/
endef

$(eval $(generic-package))
