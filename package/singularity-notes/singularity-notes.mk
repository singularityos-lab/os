################################################################################
#
# singularity-notes
#
################################################################################

SINGULARITY_NOTES_VERSION = 476153ceb02bd8c5fb1980f127b71624a9d87b15
SINGULARITY_NOTES_SITE = $(call github,singularityos-lab,singularity-notes,$(SINGULARITY_NOTES_VERSION))
SINGULARITY_NOTES_LICENSE = GPL-3.0+
SINGULARITY_NOTES_LICENSE_FILES = LICENSE
SINGULARITY_NOTES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gnutls gstreamer1 json-glib libsoup3 libxml2 pango poppler zlib

SINGULARITY_NOTES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
