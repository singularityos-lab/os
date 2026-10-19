################################################################################
#
# wl-clipboard
#
################################################################################

WL_CLIPBOARD_VERSION = 2.3.0
WL_CLIPBOARD_SITE = $(call github,bugaevc,wl-clipboard,v$(WL_CLIPBOARD_VERSION))
WL_CLIPBOARD_LICENSE = GPL-3.0-or-later
WL_CLIPBOARD_LICENSE_FILES = COPYING
WL_CLIPBOARD_DEPENDENCIES = host-pkgconf wayland wayland-protocols

$(eval $(meson-package))
