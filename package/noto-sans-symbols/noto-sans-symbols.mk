################################################################################
#
# noto-sans-symbols
#
################################################################################

NOTO_SANS_SYMBOLS_VERSION = 2026.10
NOTO_SANS_SYMBOLS_SITE = https://raw.githubusercontent.com/notofonts/notofonts.github.io
NOTO_SANS_SYMBOLS_SOURCE =
NOTO_SANS_SYMBOLS_EXTRA_DOWNLOADS = \
	NotoSansSymbols-v2.002/fonts/NotoSansSymbols/hinted/ttf/NotoSansSymbols-Regular.ttf \
	NotoSansSymbols2-v2.006/fonts/NotoSansSymbols2/hinted/ttf/NotoSansSymbols2-Regular.ttf \
	NotoSansMath-v2.539/fonts/NotoSansMath/hinted/ttf/NotoSansMath-Regular.ttf \
	NotoSansSymbols2-v2.006/fonts/LICENSE
NOTO_SANS_SYMBOLS_LICENSE = OFL-1.1
NOTO_SANS_SYMBOLS_LICENSE_FILES = LICENSE
NOTO_SANS_SYMBOLS_FONTS = NotoSansSymbols-Regular.ttf NotoSansSymbols2-Regular.ttf NotoSansMath-Regular.ttf

define NOTO_SANS_SYMBOLS_EXTRACT_CMDS
	cp $(addprefix $(NOTO_SANS_SYMBOLS_DL_DIR)/,$(NOTO_SANS_SYMBOLS_FONTS) LICENSE) $(@D)/
endef

define NOTO_SANS_SYMBOLS_INSTALL_TARGET_CMDS
	$(foreach f,$(NOTO_SANS_SYMBOLS_FONTS),\
		$(INSTALL) -D -m 0644 $(@D)/$(f) $(TARGET_DIR)/usr/share/fonts/noto-symbols/$(f)$(sep))
endef

$(eval $(generic-package))
