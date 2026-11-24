################################################################################
#
# singularity-printers
#
################################################################################

SINGULARITY_PRINTERS_VERSION = 4071bcb2bd869e6808d3ad3c5ee271a932daf86c
SINGULARITY_PRINTERS_SITE = $(call github,singularityos-lab,singularity-printers,$(SINGULARITY_PRINTERS_VERSION))
SINGULARITY_PRINTERS_LICENSE = GPL-3.0+
SINGULARITY_PRINTERS_LICENSE_FILES = LICENSE
SINGULARITY_PRINTERS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_PRINTERS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
