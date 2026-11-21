################################################################################
#
# unicorn
#
################################################################################

UNICORN_VERSION = 2.1.4
UNICORN_SITE = $(call github,unicorn-engine,unicorn,$(UNICORN_VERSION))
UNICORN_LICENSE = GPL-2.0
UNICORN_LICENSE_FILES = COPYING
UNICORN_INSTALL_STAGING = YES
UNICORN_DEPENDENCIES = python3
UNICORN_CONF_OPTS = \
	-DUNICORN_ARCH=aarch64 \
	-DUNICORN_BUILD_TESTS=OFF \
	-DUNICORN_LEGACY_STATIC_ARCHIVE=OFF \
	-DUNICORN_INSTALL=ON \
	-DBUILD_SHARED_LIBS=ON

define UNICORN_INSTALL_PYTHON_BINDINGS
	mkdir -p $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/site-packages
	cp -r $(@D)/bindings/python/unicorn \
		$(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/site-packages/
endef
UNICORN_POST_INSTALL_TARGET_HOOKS += UNICORN_INSTALL_PYTHON_BINDINGS

$(eval $(cmake-package))
