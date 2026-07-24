################################################################################
# mts -- Memory Tiering Standard userspace (Zig, memory-tiering-standard).
# Builds the mtsd daemon and the mtsctl control tool as static x86_64-musl
# binaries with the host Zig 0.16.x, so they run regardless of the target libc.
# The MTS kernel feature (CONFIG_MTS_OBSERVE/MTS_TIER, /dev/mts) is provided by
# the linux patch series wired via BR2_LINUX_KERNEL_PATCH; this package installs
# only the userspace control plane.
################################################################################
MTS_VERSION = local
MTS_SITE_METHOD = local
MTS_SITE = /home/mirko/Projects/personal/memory-tiering-standard
MTS_LICENSE = Apache-2.0
MTS_LICENSE_FILES = LICENSES/Apache-2.0.txt

MTS_ZIG ?= zig
MTS_ZIG_TARGET = x86_64-linux-musl

define MTS_BUILD_CMDS
	mkdir -p $(@D)/.zig-cache
	cd $(@D) && ZIG_GLOBAL_CACHE_DIR=$(@D)/.zig-cache/global ZIG_LOCAL_CACHE_DIR=$(@D)/.zig-cache/local \
		$(MTS_ZIG) build-exe src/mtsd.zig   -O ReleaseSafe -target $(MTS_ZIG_TARGET) -femit-bin=$(@D)/mtsd
	cd $(@D) && ZIG_GLOBAL_CACHE_DIR=$(@D)/.zig-cache/global ZIG_LOCAL_CACHE_DIR=$(@D)/.zig-cache/local \
		$(MTS_ZIG) build-exe src/mtsctl.zig -O ReleaseSafe -target $(MTS_ZIG_TARGET) -femit-bin=$(@D)/mtsctl
endef

define MTS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/mtsd   $(TARGET_DIR)/usr/sbin/mtsd
	$(INSTALL) -D -m 0755 $(@D)/mtsctl $(TARGET_DIR)/usr/bin/mtsctl
	# Default active-tiering configuration (enforce mode, file-backed cold tier).
	$(INSTALL) -D -m 0644 $(MTS_PKGDIR)/mts.conf $(TARGET_DIR)/etc/mts/mts.conf
	# sinit service (systemd-style unit) + enable it under graphical.target.
	$(INSTALL) -D -m 0644 $(MTS_PKGDIR)/mtsd.service \
		$(TARGET_DIR)/usr/lib/systemd/system/mtsd.service
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/graphical.target.wants
	ln -sf ../mtsd.service \
		$(TARGET_DIR)/usr/lib/systemd/system/graphical.target.wants/mtsd.service
endef

$(eval $(generic-package))
