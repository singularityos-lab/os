################################################################################
#
# intel-wireless-legacy-firmware
#
################################################################################

INTEL_WIRELESS_LEGACY_FIRMWARE_VERSION = a2dcb924f0897368b0b4f305cbf9808cdda90ce0
INTEL_WIRELESS_LEGACY_FIRMWARE_SITE = https://gitlab.com/kernel-firmware/linux-firmware/-/raw/$(INTEL_WIRELESS_LEGACY_FIRMWARE_VERSION)
INTEL_WIRELESS_LEGACY_FIRMWARE_SOURCE =
INTEL_WIRELESS_LEGACY_FIRMWARE_WIFI = \
	iwlwifi-3160-17.ucode \
	iwlwifi-3168-29.ucode \
	iwlwifi-7265-17.ucode \
	iwlwifi-7265D-29.ucode
INTEL_WIRELESS_LEGACY_FIRMWARE_BT = \
	ibt-hw-37.7.10-fw-1.0.1.2d.d.bseq \
	ibt-hw-37.7.10-fw-1.0.2.3.d.bseq \
	ibt-hw-37.7.10-fw-1.80.1.2d.d.bseq \
	ibt-hw-37.7.10-fw-1.80.2.3.d.bseq \
	ibt-hw-37.7.bseq \
	ibt-hw-37.8.10-fw-1.10.2.27.d.bseq \
	ibt-hw-37.8.10-fw-1.10.3.11.e.bseq \
	ibt-hw-37.8.10-fw-22.50.19.14.f.bseq \
	ibt-hw-37.8.bseq
INTEL_WIRELESS_LEGACY_FIRMWARE_EXTRA_DOWNLOADS = \
	$(addprefix intel/iwlwifi/,$(INTEL_WIRELESS_LEGACY_FIRMWARE_WIFI)) \
	$(addprefix intel/,$(INTEL_WIRELESS_LEGACY_FIRMWARE_BT)) \
	LICENSES/LICENCE.iwlwifi_firmware \
	LICENSES/LICENCE.ibt_firmware
INTEL_WIRELESS_LEGACY_FIRMWARE_LICENSE = Intel firmware license
INTEL_WIRELESS_LEGACY_FIRMWARE_LICENSE_FILES = LICENCE.iwlwifi_firmware LICENCE.ibt_firmware
INTEL_WIRELESS_LEGACY_FIRMWARE_REDISTRIBUTE = YES

define INTEL_WIRELESS_LEGACY_FIRMWARE_EXTRACT_CMDS
	cp $(addprefix $(INTEL_WIRELESS_LEGACY_FIRMWARE_DL_DIR)/,$(INTEL_WIRELESS_LEGACY_FIRMWARE_WIFI) $(INTEL_WIRELESS_LEGACY_FIRMWARE_BT) LICENCE.iwlwifi_firmware LICENCE.ibt_firmware) $(@D)/
endef

define INTEL_WIRELESS_LEGACY_FIRMWARE_INSTALL_TARGET_CMDS
	$(foreach f,$(INTEL_WIRELESS_LEGACY_FIRMWARE_WIFI),\
		$(INSTALL) -D -m 0644 $(@D)/$(f) $(TARGET_DIR)/lib/firmware/intel/iwlwifi/$(f)$(sep)\
		ln -sfn intel/iwlwifi/$(f) $(TARGET_DIR)/lib/firmware/$(f)$(sep))
	$(foreach f,$(INTEL_WIRELESS_LEGACY_FIRMWARE_BT),\
		$(INSTALL) -D -m 0644 $(@D)/$(f) $(TARGET_DIR)/lib/firmware/intel/$(f)$(sep))
endef

$(eval $(generic-package))
