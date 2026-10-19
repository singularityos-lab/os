################################################################################
#
# noto-color-emoji
#
################################################################################

NOTO_COLOR_EMOJI_VERSION = v2026-09-24-unicode18_0
NOTO_COLOR_EMOJI_SITE = https://raw.githubusercontent.com/googlefonts/noto-emoji/$(NOTO_COLOR_EMOJI_VERSION)/2D/fonts
NOTO_COLOR_EMOJI_SOURCE =
NOTO_COLOR_EMOJI_EXTRA_DOWNLOADS = NotoColorEmoji.ttf LICENSE
NOTO_COLOR_EMOJI_LICENSE = OFL-1.1
NOTO_COLOR_EMOJI_LICENSE_FILES = LICENSE

define NOTO_COLOR_EMOJI_EXTRACT_CMDS
	cp $(NOTO_COLOR_EMOJI_DL_DIR)/NotoColorEmoji.ttf $(NOTO_COLOR_EMOJI_DL_DIR)/LICENSE $(@D)/
endef

define NOTO_COLOR_EMOJI_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/NotoColorEmoji.ttf $(TARGET_DIR)/usr/share/fonts/noto-emoji/NotoColorEmoji.ttf
endef

$(eval $(generic-package))
