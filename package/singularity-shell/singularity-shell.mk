################################################################################
#
# singularity-shell
#
################################################################################

# Local dev builds from buildroot-build/local.mk _OVERRIDE_SRCDIR (build dir -custom),
# which supersedes this github SITE. Keep the pin for RC/CI (no override present).
SINGULARITY_SHELL_VERSION = 7df6616ce263c4140a2fcc07aac87fdc3dbe1499
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
