################################################################################
#
# sinty-recovery-ui (Zig 0.16)
#
################################################################################

SINTY_RECOVERY_UI_VERSION = v0.2.1
SINTY_RECOVERY_UI_SITE = https://github.com/singularityos-lab/sinty-recovery.git
SINTY_RECOVERY_UI_SITE_METHOD = git
SINTY_RECOVERY_UI_GIT_SUBMODULES = YES
SINTY_RECOVERY_UI_LICENSE = GPL-3.0-only
SINTY_RECOVERY_UI_DEPENDENCIES = \
	host-pkgconf \
	cairo \
	pango \
	gdk-pixbuf \
	wayland \
	libdrm \
	libinput \
	libxkbcommon

SINTY_RECOVERY_UI_ZIG = zig
SINTY_RECOVERY_UI_GLIBC_VERSION = $(firstword $(subst -, ,$(GLIBC_VERSION)))
SINTY_RECOVERY_UI_ZIG_TARGET = $(BR2_ARCH)-linux-gnu.$(SINTY_RECOVERY_UI_GLIBC_VERSION)

define SINTY_RECOVERY_UI_BUILD_CMDS
	cd $(@D)/ui/cairo && $(TARGET_MAKE_ENV) \
		PKG_CONFIG="$(PKG_CONFIG_HOST_BINARY)" \
		PKG_CONFIG_SYSROOT_DIR="$(STAGING_DIR)" \
		PKG_CONFIG_LIBDIR="$(STAGING_DIR)/usr/lib/pkgconfig:$(STAGING_DIR)/usr/share/pkgconfig" \
		$(SINTY_RECOVERY_UI_ZIG) build -Doptimize=ReleaseSafe \
			-Dtarget=$(SINTY_RECOVERY_UI_ZIG_TARGET) \
			-Dcpu=x86_64_v2 \
			--search-prefix $(STAGING_DIR)/usr
endef

define SINTY_RECOVERY_UI_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/ui/cairo/zig-out/bin/sinty-recovery-ui $(TARGET_DIR)/usr/bin/sinty-recovery-ui
endef

$(eval $(generic-package))
