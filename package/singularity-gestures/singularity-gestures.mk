################################################################################
#
# singularity-gestures
#
################################################################################

SINGULARITY_GESTURES_VERSION = 28f493f200adb893d0ba0a76b40c39f9c6217c7b
SINGULARITY_GESTURES_SITE = $(call github,singularityos-lab,singularity-gestures,$(SINGULARITY_GESTURES_VERSION))
SINGULARITY_GESTURES_LICENSE = LGPL-2.1+
SINGULARITY_GESTURES_LICENSE_FILES = LICENSE
SINGULARITY_GESTURES_DEPENDENCIES = host-pkgconf host-wayland libgtk4 sdl2 libglu xlib_libX11 gtk4-layer-shell wayland libxkbcommon gstreamer1 gst1-plugins-base cairo pango

define SINGULARITY_GESTURES_FETCH_RUNTIME
	cd $(@D) && bash scripts/bootstrap-runtime.sh
endef
SINGULARITY_GESTURES_PRE_CONFIGURE_HOOKS += SINGULARITY_GESTURES_FETCH_RUNTIME

$(eval $(meson-package))
