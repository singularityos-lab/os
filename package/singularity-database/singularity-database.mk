################################################################################
#
# singularity-database
#
################################################################################

SINGULARITY_DATABASE_VERSION = 56a32001992088497580e6ee9b3df67ade1ab02e
SINGULARITY_DATABASE_SITE = $(call github,singularityos-lab,singularity-database,$(SINGULARITY_DATABASE_VERSION))
SINGULARITY_DATABASE_LICENSE = GPL-3.0+
SINGULARITY_DATABASE_LICENSE_FILES = LICENSE
SINGULARITY_DATABASE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee gtksourceview json-glib libsecret libxml2 nettle pango sqlite zlib

SINGULARITY_DATABASE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_DATABASE_DEPENDENCIES += host-iride
SINGULARITY_DATABASE_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
