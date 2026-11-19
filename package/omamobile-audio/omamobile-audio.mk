################################################################################
#
# omamobile-audio
#
################################################################################

OMAMOBILE_AUDIO_VERSION = 17f9a3cd979c280431b2253e5af377e1b2377d55
OMAMOBILE_AUDIO_SITE = $(call github,derekross,omarchy-mobile,$(OMAMOBILE_AUDIO_VERSION))
OMAMOBILE_AUDIO_LICENSE = MIT
OMAMOBILE_AUDIO_LICENSE_FILES = packages/omamobile-audio/LICENSE

define OMAMOBILE_AUDIO_INSTALL_TARGET_CMDS
	bash $(@D)/packages/omamobile-audio/install $(TARGET_DIR)
	rm -f $(TARGET_DIR)/usr/lib/modprobe.d/omamobile-audio.conf \
		$(TARGET_DIR)/usr/lib/udev/rules.d/70-omamobile-cs35l41.rules
	$(SED) 's/omamobile-aoc\.service/sinty-device-setup.service/g' \
		$(TARGET_DIR)/usr/lib/systemd/system/omamobile-speaker-protection.service \
		$(TARGET_DIR)/usr/lib/systemd/system/omamobile-audio-mics.service
	mkdir -p $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants
	ln -sf /usr/lib/systemd/system/omamobile-speaker-protection.service \
		$(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/omamobile-speaker-protection.service
endef

$(eval $(generic-package))
