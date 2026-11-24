################################################################################
#
# singularity-notes
#
################################################################################

SINGULARITY_NOTES_VERSION = 2ad477c625c50d66e67c2cf5f6aae9a97c085089
SINGULARITY_NOTES_SITE = $(call github,singularityos-lab,singularity-notes,$(SINGULARITY_NOTES_VERSION))
SINGULARITY_NOTES_LICENSE = GPL-3.0+
SINGULARITY_NOTES_LICENSE_FILES = LICENSE
SINGULARITY_NOTES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gnutls gstreamer1 json-glib libsoup3 libxml2 pango poppler zlib

SINGULARITY_NOTES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_NOTES_DEPENDENCIES += host-iride
SINGULARITY_NOTES_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
