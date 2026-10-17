################################################################################
#
# sinty-tessdata
#
################################################################################

SINTY_TESSDATA_VERSION = 4.1.0
SINTY_TESSDATA_SITE = https://github.com/tesseract-ocr/tessdata_fast/raw/$(SINTY_TESSDATA_VERSION)
SINTY_TESSDATA_LANGS = eng ita deu fra spa por
SINTY_TESSDATA_SOURCE =
SINTY_TESSDATA_EXTRA_DOWNLOADS = $(addsuffix .traineddata,$(SINTY_TESSDATA_LANGS))
SINTY_TESSDATA_LICENSE = Apache-2.0
SINTY_TESSDATA_DEPENDENCIES = tesseract-ocr

define SINTY_TESSDATA_INSTALL_TARGET_CMDS
	$(foreach lang,$(SINTY_TESSDATA_LANGS), \
		$(INSTALL) -D -m 0644 $(SINTY_TESSDATA_DL_DIR)/$(lang).traineddata \
			$(TARGET_DIR)/usr/share/tessdata/$(lang).traineddata
	)
endef

$(eval $(generic-package))
