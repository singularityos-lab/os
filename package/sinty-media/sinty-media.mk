################################################################################
#
# sinty-media
#
################################################################################

SINTY_MEDIA_VERSION = d60a8f01c248d4b09c5278be4f1209f992ca215b
SINTY_MEDIA_SITE = $(call github,singularityos-lab,sinty-media,$(SINTY_MEDIA_VERSION))
SINTY_MEDIA_LICENSE = GPL-3.0
SINTY_MEDIA_LICENSE_FILES = LICENSE
SINTY_MEDIA_DEPENDENCIES = host-pkgconf gstreamer1 gst1-plugins-base gst1-plugins-good \
	libglib2 pipewire pango libgudev libdrm graphene libpng jpeg libogg zlib wayland \
	$(if $(BR2_PACKAGE_HAS_LIBGBM),libgbm) \
	$(if $(BR2_PACKAGE_HAS_LIBEGL),libegl) $(if $(BR2_PACKAGE_HAS_LIBGL),libgl) \
	$(if $(BR2_PACKAGE_XLIB_LIBX11),xlib_libX11 xlib_libXext xlib_libXi xlib_libXv) \
	$(if $(BR2_PACKAGE_GST1_PLUGINS_BAD),gst1-plugins-bad) \
	$(if $(BR2_PACKAGE_GST1_PLUGINS_UGLY),gst1-plugins-ugly)

SINTY_MEDIA_PLUGINS = adder,app,audioconvert,audiomixer,audiorate,audioresample,audiotestsrc,basedebug,compositor,coreelements,coretracers,dsd,encoding,gio,opengl,overlaycomposition,pango,pbtypes,pipewire,playback,rawparse,sintymedia,subparse,tcp,typefindfunctions,video4linux2,videoconvertscale,videocrop,videorate,videotestsrc,volume,ximagesink,xvimagesink
SINTY_MEDIA_LIBS = gstreamer gstbase gsttag gstaudio gstapp gstallocators gstcontroller gstnet gstriff gstrtp gstsdp gstrtsp gstfft gstgl gstvideo gstpbutils gstwebrtc

define SINTY_MEDIA_BUILD_CMDS
	cd $(@D) && $(TARGET_MAKE_ENV) PKG_CONFIG=$(PKG_CONFIG_HOST_BINARY) zig build -Doptimize=ReleaseSafe \
		-Dtarget=$(call qstrip,$(BR2_ARCH))-linux-gnu \
		-Dcpu=baseline \
		-Dflat-libdir=true \
		-Dplugins=$(SINTY_MEDIA_PLUGINS) \
		--search-prefix $(STAGING_DIR)/usr \
		--prefix $(@D)/out
endef

define SINTY_MEDIA_INSTALL_TARGET_CMDS
	for l in $(SINTY_MEDIA_LIBS); do rm -f $(TARGET_DIR)/usr/lib/lib$$l-1.0.so*; done
	cp -a $(@D)/out/lib/libgst*.so* $(TARGET_DIR)/usr/lib/
	mkdir -p $(TARGET_DIR)/usr/lib/gstreamer-1.0
	$(INSTALL) -m 0755 $(@D)/out/plugins/*.so $(TARGET_DIR)/usr/lib/gstreamer-1.0/
	$(INSTALL) -D -m 0755 $(@D)/out/bin/sinty-mediad $(TARGET_DIR)/usr/libexec/sinty-mediad
	$(INSTALL) -D -m 0644 $(SINTY_MEDIA_PKGDIR)/dev.sinty.MediaService.desktop \
		$(TARGET_DIR)/etc/xdg/autostart/dev.sinty.MediaService.desktop
endef

$(eval $(generic-package))
