################################################################################
#
# omamobile-camera-data
#
################################################################################

OMAMOBILE_CAMERA_DATA_VERSION = 5de4fdb2a76ad232ad06d6f69b319d3208fc1574
OMAMOBILE_CAMERA_DATA_SITE = $(call github,derekross,omarchy-mobile,$(OMAMOBILE_CAMERA_DATA_VERSION))
OMAMOBILE_CAMERA_DATA_LICENSE = MIT
OMAMOBILE_CAMERA_DATA_LICENSE_FILES = LICENSE

define OMAMOBILE_CAMERA_DATA_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/tools/extract-camera-data \
		$(TARGET_DIR)/usr/libexec/sinty/extract-camera-data
endef

$(eval $(generic-package))
