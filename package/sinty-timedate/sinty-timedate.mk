SINTY_TIMEDATE_VERSION = v0.1.0
SINTY_TIMEDATE_SITE = https://github.com/mirkobrombin/sinty-timedate/releases/download/$(SINTY_TIMEDATE_VERSION)
SINTY_TIMEDATE_SOURCE = sinty-timedate-$(SINTY_TIMEDATE_VERSION)-x86_64.tar.gz
SINTY_TIMEDATE_LICENSE = NOT-SPECIFIED

define SINTY_TIMEDATE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/sinty-timedate $(TARGET_DIR)/usr/bin/sinty-timedate
endef

$(eval $(generic-package))
