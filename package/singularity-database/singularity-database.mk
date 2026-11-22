################################################################################
#
# singularity-database
#
################################################################################

SINGULARITY_DATABASE_VERSION = 83c35b00d6d07f3d221484e72ba6ab63abaf5ca1
SINGULARITY_DATABASE_SITE = $(call github,singularityos-lab,singularity-database,$(SINGULARITY_DATABASE_VERSION))
SINGULARITY_DATABASE_LICENSE = GPL-3.0+
SINGULARITY_DATABASE_LICENSE_FILES = LICENSE
SINGULARITY_DATABASE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee gtksourceview json-glib libsecret libxml2 nettle pango sqlite zlib

SINGULARITY_DATABASE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_DATABASE_DEPENDENCIES += host-iride
SINGULARITY_DATABASE_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
