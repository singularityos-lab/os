################################################################################
#
# labwc
#
################################################################################

LABWC_VERSION = 6b0959e4c98a9124ac0798fc267b555749da7457
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

LABWC_SCENEFX_VERSION = 37ccd723bef49e6891156ffafce8f549f01446cc
LABWC_EXTRA_DOWNLOADS = \
	https://github.com/wlrfx/scenefx/archive/$(LABWC_SCENEFX_VERSION).tar.gz

define LABWC_EXTRACT_SCENEFX
	mkdir -p $(@D)/subprojects/scenefx
	$(call suitable-extractor,$(LABWC_SCENEFX_VERSION).tar.gz) \
		$(LABWC_DL_DIR)/$(LABWC_SCENEFX_VERSION).tar.gz | \
		$(TAR) --strip-components=1 -C $(@D)/subprojects/scenefx $(TAR_OPTIONS) -
	for p in scenefx-liquid.patch scenefx-software-sync.patch; do \
		patch -d $(@D)/subprojects/scenefx -p1 < $(@D)/subprojects/packagefiles/$$p || exit 1; \
	done
endef
LABWC_POST_EXTRACT_HOOKS += LABWC_EXTRACT_SCENEFX

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
