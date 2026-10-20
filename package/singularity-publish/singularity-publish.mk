################################################################################
#
# singularity-publish
#
################################################################################

SINGULARITY_PUBLISH_VERSION = 8638931e367f07a1cba513ebcda8490bf38fc313
SINGULARITY_PUBLISH_SITE = $(call github,singularityos-lab,singularity-publish,$(SINGULARITY_PUBLISH_VERSION))
SINGULARITY_PUBLISH_LICENSE = GPL-3.0+
SINGULARITY_PUBLISH_LICENSE_FILES = LICENSE
SINGULARITY_PUBLISH_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo fontconfig gdk-pixbuf libgee lcms2 librsvg libxml2 pango poppler sqlite zlib

SINGULARITY_PUBLISH_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

define SINGULARITY_PUBLISH_PDF_ENGINE
	mkdir -p $(@D)/subprojects/libsingularity
	$(if $(LIBSINGULARITY_OVERRIDE_SRCDIR),\
		rsync -a --exclude=/build --exclude=/build-* --exclude=/_build --exclude=/.git $(LIBSINGULARITY_OVERRIDE_SRCDIR)/ $(@D)/subprojects/libsingularity/,\
		$(LIBSINGULARITY_ENSURE_SOURCE); $(call suitable-extractor,$(LIBSINGULARITY_SOURCE)) $(LIBSINGULARITY_DL_DIR)/$(LIBSINGULARITY_SOURCE) | \
		$(TAR) --strip-components=1 -C $(@D)/subprojects/libsingularity $(TAR_OPTIONS) -)
endef
SINGULARITY_PUBLISH_POST_EXTRACT_HOOKS += SINGULARITY_PUBLISH_PDF_ENGINE

$(eval $(meson-package))
