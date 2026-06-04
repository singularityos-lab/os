################################################################################
#
# singularity-shell
#
################################################################################

SINGULARITY_SHELL_VERSION = edab6504770d3fb6185fe0c4e141ac3e5074517a
SINGULARITY_SHELL_SITE = $(call github,singularityos-lab,singularity-shell,$(SINGULARITY_SHELL_VERSION))
SINGULARITY_SHELL_LICENSE = GPL-3.0+
SINGULARITY_SHELL_LICENSE_FILES = LICENSE
SINGULARITY_SHELL_INSTALL_STAGING = YES
SINGULARITY_SHELL_DEPENDENCIES = \
	host-pkgconf \
	host-vala \
	host-wayland \
	gobject-introspection \
	libsingularity \
	gsettings-desktop-schemas \
	libgtk4 \
	gtk4-layer-shell \
	vte-gtk4 \
	gtksourceview \
	poppler \
	network-manager \
	upower \
	pulseaudio \
	gnome-online-accounts \
	polkit \
	linux-pam \
	libsoup3 \
	json-glib \
	libpeas2 \
	libdbusmenu \
	at-spi2-core \
	tracker \
	libgudev \
	libgee \
	wayland \
	libxcb \
	libpng

# The vala-generated C calls singularity_wayland_create_workspace() ahead of its
# prototype; GCC 14 makes implicit declarations a hard error by default. The
# function is defined in wayland_integration.c and linked, so demote it.
SINGULARITY_SHELL_CONF_OPTS = -Dc_args=-Wno-error=implicit-function-declaration

$(eval $(meson-package))
