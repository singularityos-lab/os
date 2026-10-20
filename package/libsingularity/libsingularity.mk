################################################################################
#
# libsingularity
#
################################################################################

# Local dev builds from buildroot-build/local.mk _OVERRIDE_SRCDIR (build dir -custom),
# which supersedes this github SITE. Keep the pin for RC/CI (no override present).
LIBSINGULARITY_VERSION = e7dc634e7c728fdd4e6bffd8e89ded4689b839e2
LIBSINGULARITY_SITE = $(call github,singularityos-lab,libsingularity,$(LIBSINGULARITY_VERSION))

define LIBSINGULARITY_ENSURE_SOURCE
test -f $(LIBSINGULARITY_DL_DIR)/$(LIBSINGULARITY_SOURCE) || { mkdir -p $(LIBSINGULARITY_DL_DIR) && $(WGET) -O $(LIBSINGULARITY_DL_DIR)/$(LIBSINGULARITY_SOURCE).part $(LIBSINGULARITY_SITE)/$(LIBSINGULARITY_SOURCE) && mv $(LIBSINGULARITY_DL_DIR)/$(LIBSINGULARITY_SOURCE).part $(LIBSINGULARITY_DL_DIR)/$(LIBSINGULARITY_SOURCE); }
endef
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
