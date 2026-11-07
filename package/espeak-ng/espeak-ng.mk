################################################################################
#
# espeak-ng
#
################################################################################

ESPEAK_NG_VERSION = 1.52.0
ESPEAK_NG_SITE = $(call github,espeak-ng,espeak-ng,$(ESPEAK_NG_VERSION))
ESPEAK_NG_LICENSE = GPL-3.0-or-later, BSD-2-Clause, Apache-2.0
ESPEAK_NG_LICENSE_FILES = COPYING COPYING.BSD2 COPYING.APACHE
ESPEAK_NG_INSTALL_STAGING = YES
ESPEAK_NG_DEPENDENCIES = host-espeak-ng
ESPEAK_NG_COMMON_OPTS = \
	-DUSE_MBROLA=OFF \
	-DUSE_LIBSONIC=OFF \
	-DUSE_LIBPCAUDIO=OFF \
	-DESPEAK_BUILD_MANPAGES=OFF \
	-DBUILD_TESTING=OFF
ESPEAK_NG_CONF_OPTS = $(ESPEAK_NG_COMMON_OPTS) -DBUILD_SHARED_LIBS=ON
HOST_ESPEAK_NG_CONF_OPTS = $(ESPEAK_NG_COMMON_OPTS) -DBUILD_SHARED_LIBS=OFF

define ESPEAK_NG_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(BR2_CMAKE) --build $(ESPEAK_NG_BUILDDIR) -j$(PARALLEL_JOBS) --target espeak-ng-bin
endef

define ESPEAK_NG_INSTALL_STAGING_CMDS
	cp -a $(ESPEAK_NG_BUILDDIR)/src/libespeak-ng/libespeak-ng.so* $(STAGING_DIR)/usr/lib/
	mkdir -p $(STAGING_DIR)/usr/include
	cp -a $(@D)/src/include/espeak $(@D)/src/include/espeak-ng $(STAGING_DIR)/usr/include/
endef

define ESPEAK_NG_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(ESPEAK_NG_BUILDDIR)/src/espeak-ng $(TARGET_DIR)/usr/bin/espeak-ng
	cp -a $(ESPEAK_NG_BUILDDIR)/src/libespeak-ng/libespeak-ng.so* $(TARGET_DIR)/usr/lib/
	rm -rf $(TARGET_DIR)/usr/share/espeak-ng-data
	cp -a $(HOST_DIR)/share/espeak-ng-data $(TARGET_DIR)/usr/share/espeak-ng-data
endef

$(eval $(cmake-package))
$(eval $(host-cmake-package))
