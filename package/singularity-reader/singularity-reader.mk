################################################################################
#
# singularity-reader
#
################################################################################

SINGULARITY_READER_VERSION = abd0c7c0c0148cc45fe165afa9852c9d2d0b9e83
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

define SINGULARITY_READER_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(SINGULARITY_READER_NINJA_ENV) \
		$(HOST_DIR)/bin/meson install -C $(@D)/buildroot-build --no-rebuild --skip-subprojects --destdir $(TARGET_DIR)
endef

$(eval $(meson-package))
