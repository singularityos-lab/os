################################################################################
#
# gst-plugins-rs (gtk4 paintable sink only)
#
################################################################################

# 0.13.x targets GStreamer 1.24 (the image ships gstreamer1 1.24.13).
GST_PLUGINS_RS_VERSION = 0.13.5
GST_PLUGINS_RS_SITE = https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git
GST_PLUGINS_RS_SITE_METHOD = git
GST_PLUGINS_RS_LICENSE = MPL-2.0
GST_PLUGINS_RS_LICENSE_FILES = LICENSE-MPL-2.0
GST_PLUGINS_RS_DEPENDENCIES = host-pkgconf gstreamer1 gst1-plugins-base libgtk4

# Build ONLY the gtk4 paintable sink crate; the workspace has dozens of plugins
# we do not ship. cargo-package builds the whole tree by default, so restrict it.
GST_PLUGINS_RS_CARGO_BUILD_OPTS = -p gst-plugin-gtk4

# The default cargo-package install copies binaries to /usr/bin; this is a GStreamer
# plugin shared object, so install it into the plugin search dir instead.
define GST_PLUGINS_RS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 \
		$(@D)/target/$(RUSTC_TARGET_NAME)/release/libgstgtk4.so \
		$(TARGET_DIR)/usr/lib/gstreamer-1.0/libgstgtk4.so
endef

$(eval $(cargo-package))
