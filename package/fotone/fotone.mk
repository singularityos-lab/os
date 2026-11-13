################################################################################
#
# fotone
#
################################################################################

FOTONE_VERSION = ac5a6f1a6238fb198333ff8765f5c217f37ed7a0
FOTONE_SITE = $(call github,singularityos-lab,fotone,$(FOTONE_VERSION))
FOTONE_LICENSE = LGPL-2.1+, BSD-2-Clause
FOTONE_LICENSE_FILES = LICENSE
FOTONE_ENGINE_VERSION = 2.54.2
FOTONE_EXTRA_DOWNLOADS = https://wpewebkit.org/releases/wpewebkit-$(FOTONE_ENGINE_VERSION).tar.xz
FOTONE_DEPENDENCIES = webkitgtk host-gperf host-python3 host-ruby host-unifdef host-pkgconf \
	at-spi2-core enchant expat fontconfig freetype gnutls gstreamer1 gst1-plugins-base gst1-plugins-bad \
	harfbuzz icu jpeg lcms2 libavif libdrm libepoxy libgbm libgcrypt libglib2 libgtk4 libinput libjxl \
	libpng libsecret libsoup3 libtasn1 libxkbcommon libxml2 libxslt sqlite wayland wayland-protocols \
	webp woff2 $(if $(BR2_PACKAGE_SINTY_MEDIA),sinty-media)

FOTONE_GLIBC = $(firstword $(subst -, ,$(GLIBC_VERSION)))

FOTONE_ZIG_OPTS = \
	-Doptimize=ReleaseSafe \
	-Dtarget=$(call qstrip,$(BR2_ARCH))-linux-gnu$(if $(FOTONE_GLIBC),.$(FOTONE_GLIBC)) \
	-Dcpu=baseline \
	-Dsysroot=$(STAGING_DIR) \
	-Dtriple=$(GNU_TARGET_NAME) \
	-Dgcc-toolchain=$(HOST_DIR) \
	-Djobs=$(PARALLEL_JOBS) \
	-Dgtk3=false \
	-Dengine-cmake=-DUSE_LIBHYPHEN=OFF \
	--search-prefix $(STAGING_DIR)/usr

FOTONE_STAGE = $(@D)/upstream/build/stage/usr/local

define FOTONE_BUILD_CMDS
	mkdir -p $(@D)/upstream/src
	cp $(FOTONE_DL_DIR)/wpewebkit-$(FOTONE_ENGINE_VERSION).tar.xz $(@D)/upstream/src/
	cd $(@D) && $(TARGET_MAKE_ENV) PKG_CONFIG=$(PKG_CONFIG_HOST_BINARY) env -u GIT_DIR zig build engine $(FOTONE_ZIG_OPTS)
	cd $(@D) && $(TARGET_MAKE_ENV) PKG_CONFIG=$(PKG_CONFIG_HOST_BINARY) env -u GIT_DIR zig build install $(FOTONE_ZIG_OPTS) --prefix $(@D)/out
endef

define FOTONE_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/local/lib/fotone-proxy $(TARGET_DIR)/usr/local/libexec \
		$(TARGET_DIR)/usr/local/bin $(TARGET_DIR)/usr/local/share/fotone
	cp -a $(FOTONE_STAGE)/lib/. $(TARGET_DIR)/usr/local/lib/
	rm -rf $(TARGET_DIR)/usr/local/lib/pkgconfig $(TARGET_DIR)/usr/local/lib/cmake
	cp -a $(FOTONE_STAGE)/libexec/wpe-webkit-2.0 $(TARGET_DIR)/usr/local/libexec/
	if [ -d $(FOTONE_STAGE)/share/wpe-webkit-2.0 ]; then \
		cp -a $(FOTONE_STAGE)/share/wpe-webkit-2.0 $(TARGET_DIR)/usr/local/share/; fi
	$(INSTALL) -m 0755 $(FOTONE_STAGE)/bin/WPEWebDriver $(TARGET_DIR)/usr/local/bin/WPEWebDriver
	$(INSTALL) -m 0755 $(@D)/out/libexec/wpe-webkit-2.0/fotone-sandbox \
		$(TARGET_DIR)/usr/local/libexec/wpe-webkit-2.0/fotone-sandbox
	for l in libfotone libsitwebview libocdm; do cp -P $(@D)/out/lib/$$l.so* $(TARGET_DIR)/usr/local/lib/; done
	for l in libwebkitgtk-6.0 libjavascriptcoregtk-6.0; do \
		cp -P $(@D)/out/lib/$$l.so* $(TARGET_DIR)/usr/local/lib/fotone-proxy/; done
	$(INSTALL) -m 0755 $(@D)/out/bin/fotone-viewer $(TARGET_DIR)/usr/local/libexec/fotone-viewer
	$(INSTALL) -m 0644 $(@D)/out/share/fotone/site-exceptions.json \
		$(TARGET_DIR)/usr/local/share/fotone/site-exceptions.json
	$(INSTALL) -m 0755 $(FOTONE_PKGDIR)/fotone-run $(TARGET_DIR)/usr/local/bin/fotone-run
	$(INSTALL) -m 0755 $(FOTONE_PKGDIR)/fotone-viewer $(TARGET_DIR)/usr/local/bin/fotone-viewer
	rm -f $(TARGET_DIR)/usr/lib/libwebkitgtk-6.0.so.4* $(TARGET_DIR)/usr/lib/libjavascriptcoregtk-6.0.so.1*
	ln -sf ../local/lib/fotone-proxy/libwebkitgtk-6.0.so.4 $(TARGET_DIR)/usr/lib/libwebkitgtk-6.0.so.4
	ln -sf ../local/lib/fotone-proxy/libjavascriptcoregtk-6.0.so.1 $(TARGET_DIR)/usr/lib/libjavascriptcoregtk-6.0.so.1
endef

$(eval $(generic-package))
