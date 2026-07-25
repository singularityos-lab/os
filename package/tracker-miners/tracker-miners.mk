################################################################################
#
# tracker-miners
#
################################################################################

TRACKER_MINERS_VERSION_MAJOR = 3.7
TRACKER_MINERS_VERSION = $(TRACKER_MINERS_VERSION_MAJOR).3
TRACKER_MINERS_SOURCE = tracker-miners-$(TRACKER_MINERS_VERSION).tar.xz
TRACKER_MINERS_SITE = https://download.gnome.org/sources/tracker-miners/$(TRACKER_MINERS_VERSION_MAJOR)
TRACKER_MINERS_LICENSE = GPL-2.0+
TRACKER_MINERS_LICENSE_FILES = COPYING
TRACKER_MINERS_DEPENDENCIES = \
	host-pkgconf \
	host-gettext \
	tracker \
	dbus \
	libglib2 \
	util-linux \
	icu

# systemd_user_services defaults to true and then resolves the unit directory through
# dependency('systemd'), which this config (BR2_INIT_NONE, sinit as PID 1) does not
# provide. Name the directory the target already uses instead.
TRACKER_MINERS_CONF_OPTS = \
	-Dextract=true \
	-Dminer_fs=true \
	-Dminer_rss=false \
	-Dwriteback=false \
	-Dseccomp=false \
	-Dlandlock=disabled \
	-Dcharset_detection=icu \
	-Dbattery_detection=none \
	-Dfunctional_tests=false \
	-Dman=false \
	-Dsystemd_user_services_dir=/usr/lib/systemd/user

TRACKER_MINERS_INSTALL_STAGING = YES

define TRACKER_MINERS_INSTALL_EXTRACT_SCHEMA
	$(INSTALL) -D -m 0644 $(@D)/data/org.freedesktop.Tracker.Extract.gschema.xml \
		$(STAGING_DIR)/usr/share/glib-2.0/schemas/org.freedesktop.Tracker.Extract.gschema.xml
	$(INSTALL) -D -m 0644 $(@D)/data/org.freedesktop.Tracker.Extract.gschema.xml \
		$(TARGET_DIR)/usr/share/glib-2.0/schemas/org.freedesktop.Tracker.Extract.gschema.xml
endef
TRACKER_MINERS_POST_INSTALL_STAGING_HOOKS += TRACKER_MINERS_INSTALL_EXTRACT_SCHEMA
TRACKER_MINERS_POST_INSTALL_TARGET_HOOKS += TRACKER_MINERS_INSTALL_EXTRACT_SCHEMA

$(eval $(meson-package))
