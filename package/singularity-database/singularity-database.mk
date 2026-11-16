################################################################################
#
# singularity-database
#
################################################################################

SINGULARITY_DATABASE_VERSION = 4870d8230459a062e390a1c54ba15a6444530a3c
SINGULARITY_DATABASE_SITE = $(call github,singularityos-lab,singularity-database,$(SINGULARITY_DATABASE_VERSION))
SINGULARITY_DATABASE_LICENSE = GPL-3.0+
SINGULARITY_DATABASE_LICENSE_FILES = LICENSE
SINGULARITY_DATABASE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee gtksourceview json-glib libsecret libxml2 nettle pango sqlite zlib

SINGULARITY_DATABASE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
