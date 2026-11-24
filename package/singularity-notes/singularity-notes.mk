################################################################################
#
# singularity-notes
#
################################################################################

SINGULARITY_NOTES_VERSION = 9d0d9e035bf5ec66219d83da451d8b0dbc9ef8ea
SINGULARITY_NOTES_SITE = $(call github,singularityos-lab,singularity-notes,$(SINGULARITY_NOTES_VERSION))
SINGULARITY_NOTES_LICENSE = GPL-3.0+
SINGULARITY_NOTES_LICENSE_FILES = LICENSE
SINGULARITY_NOTES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gnutls gstreamer1 json-glib libsoup3 libxml2 pango poppler zlib

SINGULARITY_NOTES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_NOTES_DEPENDENCIES += host-iride
SINGULARITY_NOTES_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
