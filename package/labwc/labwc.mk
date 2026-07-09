################################################################################
#
# labwc
#
################################################################################

LABWC_VERSION = 3c81be7eea29de8506baebae09040b3ba3e39659
LABWC_SITE = $(call github,singularityos-lab,labwc,$(LABWC_VERSION))
LABWC_LICENSE = GPL-2.0
LABWC_LICENSE_FILES = LICENSE
LABWC_DEPENDENCIES = \
	host-pkgconf \
	wlroots020 \
	wayland \
	wayland-protocols \
	libxml2 \
	cairo \
	pango \
	libglib2 \
	libdrm \
	libinput \
	libxkbcommon \
	librsvg \
	libpng \
	libxcb \
	xcb-util-wm \
	xwayland

LABWC_CONF_OPTS = \
	-Dxwayland=enabled \
	-Dman-pages=disabled \
	-Dicon=disabled

define LABWC_XKB_NO_SECURE_GETENV
	$(SED) 's/ctx_flags = XKB_CONTEXT_NO_FLAGS;/ctx_flags = XKB_CONTEXT_NO_SECURE_GETENV;/' \
		$(@D)/src/input/keyboard.c
endef
LABWC_POST_PATCH_HOOKS += LABWC_XKB_NO_SECURE_GETENV

define LABWC_XKB_GUARD_LAYOUT
	$(SED) '/static bool fallback_mode;/a\	static char desired_layout[64]; { const char *cur = getenv("XKB_DEFAULT_LAYOUT"); if (desired_layout[0] \&\& (!cur || !*cur || !strcmp(cur, "us")) \&\& strcmp(desired_layout, "us")) { setenv("XKB_DEFAULT_LAYOUT", desired_layout, 1); } else if (cur \&\& *cur \&\& strcmp(cur, "us")) { snprintf(desired_layout, sizeof desired_layout, "%s", cur); } }' \
		$(@D)/src/input/keyboard.c
endef
LABWC_POST_PATCH_HOOKS += LABWC_XKB_GUARD_LAYOUT

$(eval $(meson-package))
