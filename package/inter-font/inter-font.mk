################################################################################
#
# inter-font
#
################################################################################

INTER_FONT_VERSION = 4.1
INTER_FONT_SOURCE = Inter-$(INTER_FONT_VERSION).zip
INTER_FONT_SITE = https://github.com/rsms/inter/releases/download/v$(INTER_FONT_VERSION)
INTER_FONT_LICENSE = OFL-1.1
INTER_FONT_LICENSE_FILES = LICENSE.txt

define INTER_FONT_EXTRACT_CMDS
	$(UNZIP) -q -d $(@D) $(INTER_FONT_DL_DIR)/$(INTER_FONT_SOURCE)
endef

define INTER_FONT_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/share/fonts/inter
	cp -a $(@D)/extras/ttf/Inter-*.ttf $(TARGET_DIR)/usr/share/fonts/inter/
	$(INSTALL) -D -m 0644 $(@D)/LICENSE.txt \
		$(TARGET_DIR)/usr/share/fonts/inter/LICENSE.txt
endef

$(eval $(generic-package))
