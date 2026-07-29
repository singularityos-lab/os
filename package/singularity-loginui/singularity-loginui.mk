################################################################################
#
# singularity-loginui
#
################################################################################

# SITE=local: build from the local desktop subproject (auth_label PIN field).
# Release builds use the pinned repository version.
SINGULARITY_LOGINUI_VERSION = v0.1.0
SINGULARITY_LOGINUI_SITE = $(call github,singularityos-lab,singularity-loginui,$(SINGULARITY_LOGINUI_VERSION))
SINGULARITY_LOGINUI_LICENSE = LGPL-2.1
SINGULARITY_LOGINUI_LICENSE_FILES = LICENSE
SINGULARITY_LOGINUI_INSTALL_STAGING = YES
SINGULARITY_LOGINUI_DEPENDENCIES = \
	host-pkgconf \
	cairo \
	pango \
	gdk-pixbuf \
	wayland

# loginui's meson builds a static lib with install:false, so the public header is not
# installed by ninja. singularity-greeter/-splash resolve it via the STAGED loginui.h,
# so force-copy the (fresh, local) header into staging after every staging install.
define SINGULARITY_LOGINUI_STAGE_HEADER
	$(INSTALL) -D -m 0644 $(@D)/loginui.h $(STAGING_DIR)/usr/include/loginui.h
	mkdir -p $(STAGING_DIR)/usr/lib
	rm -f $(STAGING_DIR)/usr/lib/libloginui.a
	cd $(@D)/buildroot-build && $(TARGET_AR) crs $(STAGING_DIR)/usr/lib/libloginui.a libloginui.a.p/*.o
endef
SINGULARITY_LOGINUI_POST_INSTALL_STAGING_HOOKS += SINGULARITY_LOGINUI_STAGE_HEADER

$(eval $(meson-package))
