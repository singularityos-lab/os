################################################################################
#
# singularity-spreadsheet
#
################################################################################

SINGULARITY_SPREADSHEET_VERSION = 296b850f82db75a42110475d160fd8beed6c3639
SINGULARITY_SPREADSHEET_SITE = $(call github,singularityos-lab,singularity-spreadsheet,$(SINGULARITY_SPREADSHEET_VERSION))
SINGULARITY_SPREADSHEET_LICENSE = GPL-3.0+
SINGULARITY_SPREADSHEET_LICENSE_FILES = LICENSE
SINGULARITY_SPREADSHEET_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsoup3 libxml2 pango sqlite zlib

SINGULARITY_SPREADSHEET_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
