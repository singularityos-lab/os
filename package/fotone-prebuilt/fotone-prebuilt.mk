################################################################################
#
# fotone-prebuilt
#
################################################################################

FOTONE_PREBUILT_VERSION = 2.54.2-a995ab5.1
FOTONE_PREBUILT_SOURCE = fotone-engine-$(FOTONE_PREBUILT_VERSION)-x86_64.tar.zst
FOTONE_PREBUILT_SITE = https://github.com/singularityos-lab/fotone/releases/download/engine-$(FOTONE_PREBUILT_VERSION)
FOTONE_PREBUILT_LICENSE = LGPL-2.1+, BSD-2-Clause
FOTONE_PREBUILT_DEPENDENCIES = webkitgtk-prebuilt

define FOTONE_PREBUILT_INSTALL_TARGET_CMDS
	rm -f $(TARGET_DIR)/usr/lib/libwebkitgtk-6.0.so.4* $(TARGET_DIR)/usr/lib/libjavascriptcoregtk-6.0.so.1*
	cp -a $(@D)/usr/. $(TARGET_DIR)/usr/
endef

$(eval $(generic-package))
