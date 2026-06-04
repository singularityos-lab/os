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
	-Dtests=false

ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
GTK4_LAYER_SHELL_CONF_OPTS += -Dintrospection=true -Dvapi=true
GTK4_LAYER_SHELL_DEPENDENCIES += gobject-introspection host-vala
else
GTK4_LAYER_SHELL_CONF_OPTS += -Dintrospection=false -Dvapi=false
endif

$(eval $(meson-package))
