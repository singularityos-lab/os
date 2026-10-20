################################################################################
#
# singularity-reader
#
################################################################################

SINGULARITY_READER_VERSION = a1647f6b166af688c280345e085eb8f574665796
SINGULARITY_READER_SITE = $(call github,singularityos-lab,singularity-reader,$(SINGULARITY_READER_VERSION))
SINGULARITY_READER_LICENSE = GPL-3.0+
SINGULARITY_READER_LICENSE_FILES = LICENSE
SINGULARITY_READER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee gnutls libpeas2 libsoup3 poppler zlib

SINGULARITY_READER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

define SINGULARITY_READER_PDF_ENGINE
	mkdir -p $(@D)/subprojects/libsingularity
	$(if $(LIBSINGULARITY_OVERRIDE_SRCDIR),\
		rsync -a --exclude=/build --exclude=/build-* --exclude=/_build --exclude=/.git $(LIBSINGULARITY_OVERRIDE_SRCDIR)/ $(@D)/subprojects/libsingularity/,\
		$(LIBSINGULARITY_ENSURE_SOURCE); $(call suitable-extractor,$(LIBSINGULARITY_SOURCE)) $(LIBSINGULARITY_DL_DIR)/$(LIBSINGULARITY_SOURCE) | \
		$(TAR) --strip-components=1 -C $(@D)/subprojects/libsingularity $(TAR_OPTIONS) -)
endef
SINGULARITY_READER_POST_EXTRACT_HOOKS += SINGULARITY_READER_PDF_ENGINE

$(eval $(meson-package))
