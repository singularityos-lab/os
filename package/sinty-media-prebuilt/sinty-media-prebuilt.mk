################################################################################
#
# sinty-media-prebuilt
#
################################################################################

SINTY_MEDIA_PREBUILT_VERSION = 26A131
SINTY_MEDIA_PREBUILT_SOURCE = sinty-media-$(SINTY_MEDIA_PREBUILT_VERSION)-x86_64.tar.zst
SINTY_MEDIA_PREBUILT_SITE = https://github.com/singularityos-lab/os/releases/download/prebuilt-26A131
SINTY_MEDIA_PREBUILT_LICENSE = GPL-3.0
SINTY_MEDIA_PREBUILT_DEPENDENCIES = host-zstd gstreamer1 gst1-plugins-base gst1-plugins-good \
	$(if $(BR2_PACKAGE_GST1_PLUGINS_BAD),gst1-plugins-bad) \
	$(if $(BR2_PACKAGE_GST1_PLUGINS_UGLY),gst1-plugins-ugly)

define SINTY_MEDIA_PREBUILT_EXTRACT_CMDS
endef

define SINTY_MEDIA_PREBUILT_INSTALL_TARGET_CMDS
	for l in gstreamer gstbase gsttag gstaudio gstapp gstallocators gstcontroller gstnet gstriff gstrtp gstsdp gstrtsp gstfft gstgl gstvideo gstpbutils gstwebrtc; do rm -f $(TARGET_DIR)/usr/lib/lib$$l-1.0.so*; done
	$(HOST_DIR)/bin/zstd -dc $(SINTY_MEDIA_PREBUILT_DL_DIR)/$(SINTY_MEDIA_PREBUILT_SOURCE) | \
		$(TAR) -x -f - --strip-components=1 -C $(TARGET_DIR)
endef

$(eval $(generic-package))
