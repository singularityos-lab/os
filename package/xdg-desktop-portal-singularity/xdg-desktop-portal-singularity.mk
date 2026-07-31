################################################################################
#
# xdg-desktop-portal-singularity
#
################################################################################

XDG_DESKTOP_PORTAL_SINGULARITY_VERSION = ce39b5e92ec52446af7afe427cef4c5f6c4e10c3
XDG_DESKTOP_PORTAL_SINGULARITY_SITE = $(call github,singularityos-lab,xdg-desktop-portal-singularity,$(XDG_DESKTOP_PORTAL_SINGULARITY_VERSION))
XDG_DESKTOP_PORTAL_SINGULARITY_LICENSE = GPL-3.0+
XDG_DESKTOP_PORTAL_SINGULARITY_LICENSE_FILES = LICENSE
XDG_DESKTOP_PORTAL_SINGULARITY_DEPENDENCIES = \
	host-pkgconf \
	host-vala \
	host-wayland \
	host-gettext \
	libsingularity \
	libgtk4 \
	gtk4-layer-shell \
	libgee \
	json-glib \
	pipewire \
	wayland

$(eval $(meson-package))
