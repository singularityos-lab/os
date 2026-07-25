MTS_VERSION = v0.1.0
MTS_SITE = https://github.com/mirkobrombin/memory-tiering-standard/releases/download/$(MTS_VERSION)
MTS_SOURCE = mts-$(MTS_VERSION)-x86_64.tar.gz
MTS_LICENSE = Apache-2.0
# Flat release tarball (mtsd and mtsctl at the top level, no wrapping directory), so the
# default --strip-components=1 would strip the binaries themselves and leave nothing to
# install. Same shape as the atom-probe asset.
MTS_STRIP_COMPONENTS = 0

define MTS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/mtsd   $(TARGET_DIR)/usr/sbin/mtsd
	$(INSTALL) -D -m 0755 $(@D)/mtsctl $(TARGET_DIR)/usr/bin/mtsctl
	$(INSTALL) -D -m 0644 $(MTS_PKGDIR)/mts.conf $(TARGET_DIR)/etc/mts/mts.conf
	$(INSTALL) -D -m 0644 $(MTS_PKGDIR)/mtsd.service $(TARGET_DIR)/usr/lib/systemd/system/mtsd.service
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/graphical.target.wants
	ln -sf ../mtsd.service $(TARGET_DIR)/usr/lib/systemd/system/graphical.target.wants/mtsd.service
endef

$(eval $(generic-package))
