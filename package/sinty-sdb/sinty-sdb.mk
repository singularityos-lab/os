SINTY_SDB_VERSION = 1c2ef966eaef032860382437d2ce0e382a02774c
SINTY_SDB_SITE = $(call github,singularityos-lab,sinty-sdb,$(SINTY_SDB_VERSION))
SINTY_SDB_LICENSE = GPL-3.0-only
SINTY_SDB_GOMOD = github.com/singularityos-lab/sinty-sdb
SINTY_SDB_BUILD_TARGETS = cmd/sdb cmd/sdbd

define SINTY_SDB_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sdbd $(TARGET_DIR)/usr/bin/sdbd
	$(INSTALL) -D -m 0755 $(@D)/bin/sdb $(TARGET_DIR)/usr/bin/sdb
	$(INSTALL) -D -m 0644 $(SINTY_SDB_PKGDIR)/sdbd.service $(TARGET_DIR)/usr/lib/systemd/system/sdbd.service
endef

$(eval $(golang-package))
