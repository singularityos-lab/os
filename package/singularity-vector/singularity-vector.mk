################################################################################
#
# singularity-vector
#
################################################################################

SINGULARITY_VECTOR_VERSION = 1cc0f2575d99ca398e82ed90160c0a219f5c0b97
SINGULARITY_VECTOR_SITE = $(call github,singularityos-lab,singularity-vector,$(SINGULARITY_VECTOR_VERSION))
SINGULARITY_VECTOR_LICENSE = GPL-3.0+
SINGULARITY_VECTOR_LICENSE_FILES = LICENSE
SINGULARITY_VECTOR_DEPENDENCIES = singularity-draw host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib lcms2 libpeas2 tiff libxml2 pango zlib

SINGULARITY_VECTOR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

define SINGULARITY_VECTOR_DRAW_ENGINE
	mkdir -p $(@D)/subprojects/singularity-draw
	$(call suitable-extractor,$(SINGULARITY_DRAW_SOURCE)) $(SINGULARITY_DRAW_DL_DIR)/$(SINGULARITY_DRAW_SOURCE) | \
		$(TAR) --strip-components=1 -C $(@D)/subprojects/singularity-draw $(TAR_OPTIONS) -
	sed -i '/^vector_engine_dep = declare_dependency/a if meson.is_subproject()\n  subdir_done()\nendif' \
		$(@D)/subprojects/singularity-draw/meson.build
endef
SINGULARITY_VECTOR_POST_EXTRACT_HOOKS += SINGULARITY_VECTOR_DRAW_ENGINE

define SINGULARITY_VECTOR_PDF_ENGINE
	mkdir -p $(@D)/subprojects/libsingularity
	$(if $(LIBSINGULARITY_OVERRIDE_SRCDIR),\
		rsync -a --exclude=/build --exclude=/build-* --exclude=/_build --exclude=/.git $(LIBSINGULARITY_OVERRIDE_SRCDIR)/ $(@D)/subprojects/libsingularity/,\
		$(LIBSINGULARITY_ENSURE_SOURCE); $(call suitable-extractor,$(LIBSINGULARITY_SOURCE)) $(LIBSINGULARITY_DL_DIR)/$(LIBSINGULARITY_SOURCE) | \
		$(TAR) --strip-components=1 -C $(@D)/subprojects/libsingularity $(TAR_OPTIONS) -)
endef
SINGULARITY_VECTOR_POST_EXTRACT_HOOKS += SINGULARITY_VECTOR_PDF_ENGINE

$(eval $(meson-package))
