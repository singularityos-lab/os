################################################################################
#
# libsingularity
#
################################################################################

# Local dev builds from buildroot-build/local.mk _OVERRIDE_SRCDIR (build dir -custom),
# which supersedes this github SITE. Keep the pin for RC/CI (no override present).
LIBSINGULARITY_VERSION = 8cb3e804a94676b2285ba61da524e94f21b9ff42
LIBSINGULARITY_SITE = $(call github,singularityos-lab,libsingularity,$(LIBSINGULARITY_VERSION))
LIBSINGULARITY_LICENSE = GPL-3.0+
LIBSINGULARITY_LICENSE_FILES = LICENSE
LIBSINGULARITY_INSTALL_STAGING = YES
LIBSINGULARITY_DEPENDENCIES = \
	host-pkgconf \
	host-vala \
	gobject-introspection \
	libgtk4 \
	gtk4-layer-shell \
	libgee \
	json-glib \
	libpeas2 \
	gtksourceview \
	pulseaudio \
	libgudev \
	upower \
	network-manager \
	libsoup3 \
	cups \
	lcms2 \
	enchant \
	gstreamer1 \
	gst1-plugins-base

LIBSINGULARITY_CONF_OPTS = -Dsystem=true

define LIBSINGULARITY_INSTALL_CUPS_VAPI
	$(INSTALL) -D -m 0644 $(LIBSINGULARITY_PKGDIR)/cups.vapi $(STAGING_DIR)/usr/share/vala/vapi/cups.vapi
endef
LIBSINGULARITY_PRE_CONFIGURE_HOOKS += LIBSINGULARITY_INSTALL_CUPS_VAPI

$(eval $(meson-package))
