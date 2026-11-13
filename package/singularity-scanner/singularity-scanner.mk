################################################################################
#
# singularity-scanner
#
################################################################################

SINGULARITY_SCANNER_VERSION = ac868d3382ecda641168a42b400719d81a54c511
SINGULARITY_SCANNER_SITE = $(call github,singularityos-lab,singularity-scanner,$(SINGULARITY_SCANNER_VERSION))
SINGULARITY_SCANNER_LICENSE = GPL-3.0+
SINGULARITY_SCANNER_LICENSE_FILES = LICENSE
SINGULARITY_SCANNER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo libgee sane-backends

SINGULARITY_SCANNER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

define SINGULARITY_SCANNER_PDF_ENGINE
	mkdir -p $(@D)/subprojects/libsingularity
	$(if $(LIBSINGULARITY_OVERRIDE_SRCDIR),\
		rsync -a --exclude=/build --exclude=/build-* --exclude=/_build --exclude=/.git $(LIBSINGULARITY_OVERRIDE_SRCDIR)/ $(@D)/subprojects/libsingularity/,\
		$(LIBSINGULARITY_ENSURE_SOURCE); $(call suitable-extractor,$(LIBSINGULARITY_SOURCE)) $(LIBSINGULARITY_DL_DIR)/$(LIBSINGULARITY_SOURCE) | \
		$(TAR) --strip-components=1 -C $(@D)/subprojects/libsingularity $(TAR_OPTIONS) -)
endef
SINGULARITY_SCANNER_POST_EXTRACT_HOOKS += SINGULARITY_SCANNER_PDF_ENGINE

define SINGULARITY_SCANNER_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(SINGULARITY_SCANNER_NINJA_ENV) \
		$(HOST_DIR)/bin/meson install -C $(@D)/buildroot-build --no-rebuild --skip-subprojects --destdir $(TARGET_DIR)
endef

SINGULARITY_SCANNER_DEPENDENCIES += host-zig
SINGULARITY_SCANNER_CONF_OPTS += \
	-Dlibsingularity:zig=$(HOST_DIR)/bin/zig \
	-Dlibsingularity:zig-target=$(call qstrip,$(BR2_ARCH))-linux-gnu \
	-Dlibsingularity:zig-cpu=baseline

$(eval $(meson-package))
