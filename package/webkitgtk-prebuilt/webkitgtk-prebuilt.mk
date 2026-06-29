################################################################################
#
# webkitgtk-prebuilt
#
################################################################################

# FIXME: webkitgtk must be part of the build process.

WEBKITGTK_PREBUILT_VERSION = 2.52.3
WEBKITGTK_PREBUILT_ARCH = $(call qstrip,$(BR2_ARCH))
WEBKITGTK_PREBUILT_SOURCE = \
	webkitgtk-prebuilt-$(WEBKITGTK_PREBUILT_VERSION)-$(WEBKITGTK_PREBUILT_ARCH).tar.zst
WEBKITGTK_PREBUILT_SITE = $(BR2_EXTERNAL_SINGULARITY_PATH)/prebuilt
WEBKITGTK_PREBUILT_SITE_METHOD = file
WEBKITGTK_PREBUILT_LICENSE = LGPL-2.0+, BSD-2-Clause
WEBKITGTK_PREBUILT_INSTALL_STAGING = YES

WEBKITGTK_PREBUILT_DEPENDENCIES = \
	host-vala \
	enchant harfbuzz icu jpeg libegl libepoxy libgcrypt libsecret \
	libsoup3 libtasn1 libxml2 libxslt sqlite webp woff2 \
	libgtk4 libgbm libdrm systemd

define WEBKITGTK_PREBUILT_INSTALL_STAGING_CMDS
	cp -a $(@D)/staging/. $(STAGING_DIR)/
	mkdir -p $(HOST_DIR)/share/vala-0.56/vapi
	cp -a $(WEBKITGTK_PREBUILT_PKGDIR)/vapi/. $(HOST_DIR)/share/vala-0.56/vapi/
endef

define WEBKITGTK_PREBUILT_INSTALL_TARGET_CMDS
	cp -a $(@D)/target/. $(TARGET_DIR)/
endef

$(eval $(generic-package))
