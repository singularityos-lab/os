################################################################################
#
# mangohud
#
################################################################################

MANGOHUD_VERSION = 0.8.4
MANGOHUD_SITE = https://github.com/flightlessmango/MangoHud/releases/download/v$(MANGOHUD_VERSION)
MANGOHUD_SOURCE = MangoHud-v$(MANGOHUD_VERSION)-Source.tar.xz
MANGOHUD_LICENSE = MIT
MANGOHUD_LICENSE_FILES = LICENSE
MANGOHUD_DEPENDENCIES = host-pkgconf host-glslang host-python3 host-python-mako dbus libx11 libxkbcommon wayland vulkan-loader
MANGOHUD_CONF_OPTS = \
	-Dwith_xnvctrl=disabled \
	-Dwith_nvml=enabled \
	-Dwith_x11=enabled \
	-Dwith_wayland=enabled \
	-Dwith_dbus=enabled \
	-Dmangoplot=disabled \
	-Dtests=disabled \
	-Dinclude_doc=true \
	--wrap-mode=nodownload

$(eval $(meson-package))
