################################################################################
#
# singularity-media-plugins
#
################################################################################

SINGULARITY_MEDIA_PLUGINS_VERSION = 856a88f2e81e40470958f34a8037f6981e5027f4
SINGULARITY_MEDIA_PLUGINS_SITE = $(call github,singularityos-lab,singularity-media-plugins,$(SINGULARITY_MEDIA_PLUGINS_VERSION))
SINGULARITY_MEDIA_PLUGINS_LICENSE = GPL-3.0+
SINGULARITY_MEDIA_PLUGINS_LICENSE_FILES = LICENSE
SINGULARITY_MEDIA_PLUGINS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libpeas2 libsoup3 libxml2 $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk)

SINGULARITY_MEDIA_PLUGINS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_MEDIA_PLUGINS_DEPENDENCIES += host-rustc
SINGULARITY_MEDIA_PLUGINS_RUST_TARGET = $(subst -,_,$(RUSTC_TARGET_NAME))
SINGULARITY_MEDIA_PLUGINS_NINJA_ENV += \
	CARGO_BUILD_TARGET=$(RUSTC_TARGET_NAME) \
	CARGO_TARGET_$(call UPPERCASE,$(RUSTC_TARGET_NAME))_LINKER=$(TARGET_CC) \
	CC_$(SINGULARITY_MEDIA_PLUGINS_RUST_TARGET)=$(TARGET_CC) \
	AR_$(SINGULARITY_MEDIA_PLUGINS_RUST_TARGET)=$(TARGET_AR)

SINGULARITY_MEDIA_PLUGINS_DEPENDENCIES += host-iride
SINGULARITY_MEDIA_PLUGINS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
