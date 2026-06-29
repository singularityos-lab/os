################################################################################
#
# gtk4-layer-shell
#
################################################################################

GTK4_LAYER_SHELL_VERSION = 1.3.0
GTK4_LAYER_SHELL_SITE = $(call github,wmww,gtk4-layer-shell,v$(GTK4_LAYER_SHELL_VERSION))
GTK4_LAYER_SHELL_LICENSE = MIT
GTK4_LAYER_SHELL_LICENSE_FILES = LICENSE
GTK4_LAYER_SHELL_INSTALL_STAGING = YES
GTK4_LAYER_SHELL_DEPENDENCIES = host-pkgconf libgtk4 wayland wayland-protocols

GTK4_LAYER_SHELL_CONF_OPTS = \
	-Dexamples=false \
	-Ddocs=false \
	-Dtests=false \
	-Dintrospection=false \
	-Dvapi=false

define GTK4_LAYER_SHELL_INSTALL_VAPI
	mkdir -p $(STAGING_DIR)/usr/share/vala/vapi
	cp -a $(GTK4_LAYER_SHELL_PKGDIR)/vapi/. $(STAGING_DIR)/usr/share/vala/vapi/
	mkdir -p $(HOST_DIR)/share/vala-0.56/vapi
	cp -a $(GTK4_LAYER_SHELL_PKGDIR)/vapi/. $(HOST_DIR)/share/vala-0.56/vapi/
endef
GTK4_LAYER_SHELL_POST_INSTALL_STAGING_HOOKS += GTK4_LAYER_SHELL_INSTALL_VAPI

$(eval $(meson-package))
