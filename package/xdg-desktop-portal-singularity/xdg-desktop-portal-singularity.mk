################################################################################
#
# xdg-desktop-portal-singularity
#
################################################################################

XDG_DESKTOP_PORTAL_SINGULARITY_VERSION = 7c815d1fc8158f7603126f0becac3210cb13c3db
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

define XDG_DESKTOP_PORTAL_SINGULARITY_LIBSINGULARITY_SUBPROJECT
	mkdir -p $(@D)/subprojects
	rsync -a --delete --exclude=/build --exclude=/build-* --exclude=.git $(or $(LIBSINGULARITY_OVERRIDE_SRCDIR),$(LIBSINGULARITY_DIR))/ $(@D)/subprojects/libsingularity/
endef
XDG_DESKTOP_PORTAL_SINGULARITY_PRE_CONFIGURE_HOOKS += XDG_DESKTOP_PORTAL_SINGULARITY_LIBSINGULARITY_SUBPROJECT

define XDG_DESKTOP_PORTAL_SINGULARITY_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(XDG_DESKTOP_PORTAL_SINGULARITY_NINJA_ENV) \
		$(HOST_DIR)/bin/meson install -C $(@D)/buildroot-build --no-rebuild --skip-subprojects --destdir $(TARGET_DIR)
endef

$(eval $(meson-package))
