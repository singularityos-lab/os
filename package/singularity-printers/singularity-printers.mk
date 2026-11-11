################################################################################
#
# singularity-printers
#
################################################################################

SINGULARITY_PRINTERS_VERSION = 8e5be5caccdcba6094d7caed52ab59fda6bb8e34
SINGULARITY_PRINTERS_SITE = $(call github,singularityos-lab,singularity-printers,$(SINGULARITY_PRINTERS_VERSION))
SINGULARITY_PRINTERS_LICENSE = GPL-3.0+
SINGULARITY_PRINTERS_LICENSE_FILES = LICENSE
SINGULARITY_PRINTERS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_PRINTERS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
