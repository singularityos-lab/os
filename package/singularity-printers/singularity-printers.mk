################################################################################
#
# singularity-printers
#
################################################################################

SINGULARITY_PRINTERS_VERSION = 24a249fbb95ff56d80ca7f418f090366762163d7
SINGULARITY_PRINTERS_SITE = $(call github,singularityos-lab,singularity-printers,$(SINGULARITY_PRINTERS_VERSION))
SINGULARITY_PRINTERS_LICENSE = GPL-3.0+
SINGULARITY_PRINTERS_LICENSE_FILES = LICENSE
SINGULARITY_PRINTERS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_PRINTERS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
