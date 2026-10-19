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
INTEL_WIRELESS_LEGACY_FIRMWARE_EXTRA_DOWNLOADS = \
	$(addprefix intel/iwlwifi/,$(INTEL_WIRELESS_LEGACY_FIRMWARE_WIFI)) \
	LICENSES/LICENCE.iwlwifi_firmware
INTEL_WIRELESS_LEGACY_FIRMWARE_LICENSE = Intel firmware license
INTEL_WIRELESS_LEGACY_FIRMWARE_LICENSE_FILES = LICENCE.iwlwifi_firmware
INTEL_WIRELESS_LEGACY_FIRMWARE_REDISTRIBUTE = YES

define INTEL_WIRELESS_LEGACY_FIRMWARE_EXTRACT_CMDS
	cp $(addprefix $(INTEL_WIRELESS_LEGACY_FIRMWARE_DL_DIR)/,$(INTEL_WIRELESS_LEGACY_FIRMWARE_WIFI) LICENCE.iwlwifi_firmware) $(@D)/
endef

define INTEL_WIRELESS_LEGACY_FIRMWARE_INSTALL_TARGET_CMDS
	$(foreach f,$(INTEL_WIRELESS_LEGACY_FIRMWARE_WIFI),\
		$(INSTALL) -D -m 0644 $(@D)/$(f) $(TARGET_DIR)/lib/firmware/intel/iwlwifi/$(f)$(sep)\
		ln -sfn intel/iwlwifi/$(f) $(TARGET_DIR)/lib/firmware/$(f)$(sep))
endef

$(eval $(generic-package))
