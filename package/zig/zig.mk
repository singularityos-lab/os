################################################################################
#
# zig
#
################################################################################

ZIG_VERSION = 0.16.0
ZIG_SOURCE = zig-x86_64-linux-$(ZIG_VERSION).tar.xz
ZIG_SITE = https://ziglang.org/download/$(ZIG_VERSION)
ZIG_LICENSE = MIT
ZIG_LICENSE_FILES = LICENSE

define HOST_ZIG_INSTALL_CMDS
	rm -rf $(HOST_DIR)/lib/zig-toolchain
	mkdir -p $(HOST_DIR)/lib/zig-toolchain $(HOST_DIR)/bin
	cp -a $(@D)/. $(HOST_DIR)/lib/zig-toolchain/
	ln -sf ../lib/zig-toolchain/zig $(HOST_DIR)/bin/zig
endef

$(eval $(host-generic-package))
