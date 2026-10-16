################################################################################
#
# singularity-keyframe
#
################################################################################

SINGULARITY_KEYFRAME_VERSION = 79913aa23197bc92fba9acd160a409b2cebdcb74
SINGULARITY_KEYFRAME_SITE = $(call github,singularityos-lab,singularity-keyframe,$(SINGULARITY_KEYFRAME_VERSION))
SINGULARITY_KEYFRAME_LICENSE = GPL-3.0+
SINGULARITY_KEYFRAME_LICENSE_FILES = LICENSE
SINGULARITY_KEYFRAME_DEPENDENCIES = singularity-draw host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee gstreamer1 gst1-plugins-base json-glib libpeas2 pango zlib

SINGULARITY_KEYFRAME_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

define SINGULARITY_KEYFRAME_DRAW_ENGINE
	mkdir -p $(@D)/subprojects/singularity-draw
	$(call suitable-extractor,$(SINGULARITY_DRAW_SOURCE)) $(SINGULARITY_DRAW_DL_DIR)/$(SINGULARITY_DRAW_SOURCE) | \
		$(TAR) --strip-components=1 -C $(@D)/subprojects/singularity-draw $(TAR_OPTIONS) -
	sed -i '/^vector_engine_dep = declare_dependency/a if meson.is_subproject()\n  subdir_done()\nendif' \
		$(@D)/subprojects/singularity-draw/meson.build
endef
SINGULARITY_KEYFRAME_POST_EXTRACT_HOOKS += SINGULARITY_KEYFRAME_DRAW_ENGINE

$(eval $(meson-package))
