################################################################################
#
# vte-gtk4
#
################################################################################

VTE_GTK4_VERSION_MAJOR = 0.84
VTE_GTK4_VERSION = $(VTE_GTK4_VERSION_MAJOR).0
VTE_GTK4_SOURCE = vte-$(VTE_GTK4_VERSION).tar.xz
VTE_GTK4_SITE = https://download.gnome.org/sources/vte/$(VTE_GTK4_VERSION_MAJOR)
VTE_GTK4_LICENSE = LGPL-3.0+
VTE_GTK4_LICENSE_FILES = COPYING.LGPL3
VTE_GTK4_CPE_ID_VENDOR = gnome
VTE_GTK4_INSTALL_STAGING = YES
VTE_GTK4_DEPENDENCIES = host-pkgconf libgtk4 pcre2 lz4 $(TARGET_NLS_DEPENDENCIES)

VTE_GTK4_CONF_OPTS = \
	-Dgtk3=false \
	-Dgtk4=true \
	-Ddocs=false

ifeq ($(BR2_PACKAGE_ICU),y)
VTE_GTK4_CONF_OPTS += -Dicu=true
VTE_GTK4_DEPENDENCIES += icu
else
VTE_GTK4_CONF_OPTS += -Dicu=false
endif

VTE_GTK4_CONF_OPTS += -Dgir=false -Dvapi=false

define VTE_GTK4_INSTALL_VAPI
	mkdir -p $(STAGING_DIR)/usr/share/vala/vapi
	cp -a $(VTE_GTK4_PKGDIR)/vapi/. $(STAGING_DIR)/usr/share/vala/vapi/
	mkdir -p $(HOST_DIR)/share/vala-0.56/vapi
	cp -a $(VTE_GTK4_PKGDIR)/vapi/. $(HOST_DIR)/share/vala-0.56/vapi/
endef
VTE_GTK4_POST_INSTALL_STAGING_HOOKS += VTE_GTK4_INSTALL_VAPI

ifeq ($(BR2_PACKAGE_GNUTLS),y)
VTE_GTK4_CONF_OPTS += -Dgnutls=true
VTE_GTK4_DEPENDENCIES += gnutls
else
VTE_GTK4_CONF_OPTS += -Dgnutls=false
endif

ifeq ($(BR2_PACKAGE_LIBFRIBIDI),y)
VTE_GTK4_CONF_OPTS += -Dfribidi=true
VTE_GTK4_DEPENDENCIES += libfribidi
else
VTE_GTK4_CONF_OPTS += -Dfribidi=false
endif

ifeq ($(BR2_PACKAGE_SYSTEMD),y)
VTE_GTK4_CONF_OPTS += -D_systemd=true
VTE_GTK4_DEPENDENCIES += systemd
else
VTE_GTK4_CONF_OPTS += -D_systemd=false
endif

define VTE_GTK4_REMOVE_DEMO_APP
	rm -f $(TARGET_DIR)/usr/bin/vte-2.91-gtk4
	rm -f $(TARGET_DIR)/usr/share/applications/org.gnome.Vte.App.Gtk4.desktop
endef
VTE_GTK4_POST_INSTALL_TARGET_HOOKS += VTE_GTK4_REMOVE_DEMO_APP

$(eval $(meson-package))
