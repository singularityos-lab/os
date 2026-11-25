SINTY_SDB_VERSION = a6e109b47916ccc3033d30c6807555fe87ecfa8e
SINTY_SDB_SITE = $(call github,singularityos-lab,sinty-sdb,$(SINTY_SDB_VERSION))
SINTY_SDB_LICENSE = GPL-3.0-only
SINTY_SDB_GOMOD = github.com/singularityos-lab/sinty-sdb
SINTY_SDB_BUILD_TARGETS = cmd/sdb cmd/sdbd

define SINTY_SDB_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_SDB_PRE_BUILD_HOOKS += SINTY_SDB_GO_VENDOR

define SINTY_SDB_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sdbd $(TARGET_DIR)/usr/bin/sdbd
	$(INSTALL) -D -m 0755 $(@D)/bin/sdb $(TARGET_DIR)/usr/bin/sdb
	$(INSTALL) -D -m 0644 $(SINTY_SDB_PKGDIR)/sdbd.service $(TARGET_DIR)/usr/lib/systemd/system/sdbd.service
endef

$(eval $(golang-package))
