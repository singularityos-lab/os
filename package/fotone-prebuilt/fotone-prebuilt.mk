################################################################################
#
# fotone-prebuilt
#
################################################################################

FOTONE_PREBUILT_ARCH = $(call qstrip,$(BR2_ARCH))
FOTONE_PREBUILT_VERSION = $(FOTONE_ENGINE_VERSION)-$(shell printf %.7s $(FOTONE_VERSION)).1
FOTONE_PREBUILT_SOURCE = fotone-engine-$(FOTONE_PREBUILT_VERSION)-$(FOTONE_PREBUILT_ARCH).tar.zst
FOTONE_PREBUILT_SITE = https://github.com/singularityos-lab/fotone/releases/download/engine-$(FOTONE_PREBUILT_VERSION)
FOTONE_PREBUILT_LICENSE = LGPL-2.1+, BSD-2-Clause
FOTONE_PREBUILT_DEPENDENCIES = $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk) host-patchelf libjxl dav1d

define FOTONE_PREBUILT_INSTALL_TARGET_CMDS
	rm -f $(TARGET_DIR)/usr/lib/libwebkitgtk-6.0.so.4* $(TARGET_DIR)/usr/lib/libjavascriptcoregtk-6.0.so.1*
	cp -a $(@D)/usr/. $(TARGET_DIR)/usr/
	PATCHELF=$(HOST_DIR)/bin/patchelf $(BR2_EXTERNAL_SINGULARITY_PATH)/package/fotone/fotone-fixup $(TARGET_DIR)
endef

$(eval $(generic-package))
