################################################################################
#
# singularity-spreadsheet
#
################################################################################

SINGULARITY_SPREADSHEET_VERSION = d4531d1123cd3ea03f6cd2d8cdabc5488602b7d2
SINGULARITY_SPREADSHEET_SITE = $(call github,singularityos-lab,singularity-spreadsheet,$(SINGULARITY_SPREADSHEET_VERSION))
SINGULARITY_SPREADSHEET_LICENSE = GPL-3.0+
SINGULARITY_SPREADSHEET_LICENSE_FILES = LICENSE
SINGULARITY_SPREADSHEET_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsoup3 libxml2 pango sqlite zlib

SINGULARITY_SPREADSHEET_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
