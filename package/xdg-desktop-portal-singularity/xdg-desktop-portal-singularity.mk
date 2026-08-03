################################################################################
#
# xdg-desktop-portal-singularity
#
################################################################################

XDG_DESKTOP_PORTAL_SINGULARITY_VERSION = 09b551a5ce3be5cd11a4ecb7c40c49fd11170a44
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
