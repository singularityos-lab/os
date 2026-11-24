################################################################################
#
# singularity-spreadsheet
#
################################################################################

SINGULARITY_SPREADSHEET_VERSION = 16269000f4e8c58efa632512b98dd5677eafceeb
SINGULARITY_SPREADSHEET_SITE = $(call github,singularityos-lab,singularity-spreadsheet,$(SINGULARITY_SPREADSHEET_VERSION))
SINGULARITY_SPREADSHEET_LICENSE = GPL-3.0+
SINGULARITY_SPREADSHEET_LICENSE_FILES = LICENSE
SINGULARITY_SPREADSHEET_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsoup3 libxml2 pango sqlite zlib

SINGULARITY_SPREADSHEET_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_SPREADSHEET_DEPENDENCIES += host-iride
SINGULARITY_SPREADSHEET_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
