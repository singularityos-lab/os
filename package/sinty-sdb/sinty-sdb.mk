SINTY_SDB_VERSION = v0.1.0
SINTY_SDB_SITE = https://github.com/singularityos-lab/sinty-sdb/releases/download/$(SINTY_SDB_VERSION)
SINTY_SDB_SOURCE = sinty-sdb-$(SINTY_SDB_VERSION)-x86_64.tar.gz
SINTY_SDB_LICENSE = GPL-3.0-only
# Flat release tarball (payload at the top level, no wrapping directory): the default
# --strip-components=1 would strip the payload itself and leave the build dir empty.
SINTY_SDB_STRIP_COMPONENTS = 0

define SINTY_SDB_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/sdbd $(TARGET_DIR)/usr/bin/sdbd
	$(INSTALL) -D -m 0755 $(@D)/sdb $(TARGET_DIR)/usr/bin/sdb
	$(INSTALL) -D -m 0644 $(@D)/sdbd.service $(TARGET_DIR)/usr/lib/systemd/system/sdbd.service
endef

$(eval $(generic-package))
