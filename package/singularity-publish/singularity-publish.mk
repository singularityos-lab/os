################################################################################
#
# singularity-publish
#
################################################################################

SINGULARITY_PUBLISH_VERSION = 284c980323154f2959b9d06ee689fe8784cd2654
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

define SINGULARITY_PUBLISH_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(SINGULARITY_PUBLISH_NINJA_ENV) \
		$(HOST_DIR)/bin/meson install -C $(@D)/buildroot-build --no-rebuild --skip-subprojects --destdir $(TARGET_DIR)
endef

SINGULARITY_PUBLISH_DEPENDENCIES += host-zig
SINGULARITY_PUBLISH_CONF_OPTS += \
	-Dlibsingularity:zig=$(HOST_DIR)/bin/zig \
	-Dlibsingularity:zig-target=$(call qstrip,$(BR2_ARCH))-linux-gnu \
	-Dlibsingularity:zig-cpu=baseline

$(eval $(meson-package))
