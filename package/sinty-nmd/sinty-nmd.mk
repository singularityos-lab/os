################################################################################
# sinty-nmd
################################################################################
# sinty-nmd, the network manager daemon, fetched as a prebuilt release asset
# from the sinty-nm repository rather than committed as a binary or rebuilt from
# source here. The sinty-nm release CI builds the static binary (CGO_ENABLED=0,
# trimpath) and attaches the tarball to the tagged release; this package just
# downloads and installs it.
#
# DRAFT: bump SINTY_NMD_VERSION to the first tag sinty-nm publishes, then enable
# BR2_PACKAGE_SINTY_NMD and drop the committed rootfs-overlay/usr/bin/sinty-nmd.
SINTY_NMD_VERSION = v0.1.0
SINTY_NMD_SITE = https://github.com/singularityos-lab/sinty-nm/releases/download/$(SINTY_NMD_VERSION)
SINTY_NMD_SOURCE = sinty-nmd-$(SINTY_NMD_VERSION)-x86_64.tar.gz
SINTY_NMD_LICENSE = GPL-3.0-or-later

define SINTY_NMD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/sinty-nmd $(TARGET_DIR)/usr/bin/sinty-nmd
endef

$(eval $(generic-package))
