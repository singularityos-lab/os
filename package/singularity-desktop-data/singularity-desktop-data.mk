################################################################################
#
# singularity-desktop-data
#
################################################################################

SINGULARITY_DESKTOP_DATA_VERSION = 0f37cd995a5a26f1adf398bbf4b3c32b33d9e207
SINGULARITY_DESKTOP_DATA_SITE = $(call github,singularityos-lab,singularity-desktop,$(SINGULARITY_DESKTOP_DATA_VERSION))
SINGULARITY_DESKTOP_DATA_LICENSE = GPL-3.0+
SINGULARITY_DESKTOP_DATA_LICENSE_FILES = LICENSE

SINGULARITY_DESKTOP_DATA_INSTALL_STAGING = YES

define SINGULARITY_DESKTOP_DATA_FIX_DOCK_DEFAULTS
	$(SED) "s|<default>\['firefox.desktop'.*</default>|<default>['dev.sinty.files.desktop', 'dev.sinty.photos.desktop', 'dev.sinty.music.desktop', 'dev.sinty.store.desktop', 'dev.sinty.write.desktop', 'dev.sinty.calculator.desktop']</default>|" \
		$(@D)/data/dev.sinty.desktop.gschema.xml
endef
SINGULARITY_DESKTOP_DATA_POST_PATCH_HOOKS += SINGULARITY_DESKTOP_DATA_FIX_DOCK_DEFAULTS

define SINGULARITY_DESKTOP_DATA_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0644 $(@D)/data/dev.sinty.desktop.gschema.xml \
		$(STAGING_DIR)/usr/share/glib-2.0/schemas/dev.sinty.desktop.gschema.xml
endef

define SINGULARITY_DESKTOP_DATA_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/data/dev.sinty.desktop.gschema.xml \
		$(TARGET_DIR)/usr/share/glib-2.0/schemas/dev.sinty.desktop.gschema.xml
	$(INSTALL) -D -m 0644 $(@D)/data/singularity.portal \
		$(TARGET_DIR)/usr/share/xdg-desktop-portal/portals/singularity.portal
	$(INSTALL) -D -m 0644 $(@D)/data/accountsservice/com.singularity.Desktop.xml \
		$(TARGET_DIR)/usr/share/accountsservice/interfaces/com.singularity.Desktop.xml
	$(INSTALL) -D -m 0644 $(@D)/data/icons/hicolor/scalable/apps/emblem-singularity.svg \
		$(TARGET_DIR)/usr/share/icons/hicolor/scalable/apps/emblem-singularity.svg
	$(INSTALL) -D -m 0644 $(@D)/data/systemd/singularity-polkit-agent.service \
		$(TARGET_DIR)/usr/lib/systemd/user/singularity-polkit-agent.service
	$(INSTALL) -D -m 0644 $(@D)/data/systemd/xdg-desktop-portal-singularity.service \
		$(TARGET_DIR)/usr/lib/systemd/user/xdg-desktop-portal-singularity.service
	cp -r $(@D)/data/icons/hicolor $(TARGET_DIR)/usr/share/icons/
endef

$(eval $(generic-package))
