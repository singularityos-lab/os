################################################################################
#
# sinty-words
#
################################################################################

SINTY_WORDS_VERSION = 85ad08bde14655563c5ea256ef95f7692f39447b
SINTY_WORDS_SITE = $(call github,singularityos-lab,sinty-words,$(SINTY_WORDS_VERSION))
SINTY_WORDS_LICENSE = CC-BY-SA-4.0
SINTY_WORDS_LICENSE_FILES = LICENSE

define SINTY_WORDS_INSTALL_TARGET_CMDS
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/share/sinty/words
	$(INSTALL) -m 0644 $(@D)/data/*.words $(TARGET_DIR)/usr/share/sinty/words/
endef

$(eval $(generic-package))
