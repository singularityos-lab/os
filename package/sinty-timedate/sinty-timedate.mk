SINTY_TIMEDATE_VERSION = v0.1.0
SINTY_TIMEDATE_SITE = https://github.com/singularityos-lab/sinty-timedate/releases/download/$(SINTY_TIMEDATE_VERSION)
SINTY_TIMEDATE_SOURCE = sinty-timedate-$(SINTY_TIMEDATE_VERSION)-x86_64.tar.gz
SINTY_TIMEDATE_LICENSE = NOT-SPECIFIED
# Flat release tarball (payload at the top level, no wrapping directory): the default
# --strip-components=1 would strip the payload itself and leave the build dir empty.
SINTY_TIMEDATE_STRIP_COMPONENTS = 0

define SINTY_TIMEDATE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/sinty-timedate $(TARGET_DIR)/usr/bin/sinty-timedate
endef

$(eval $(generic-package))
