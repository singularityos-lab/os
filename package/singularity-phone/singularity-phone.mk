################################################################################
#
# singularity-phone
#
################################################################################

SINGULARITY_PHONE_VERSION = bf1bcf90eaa65f4521664f99a197b705161a95a4
SINGULARITY_PHONE_SITE = $(call github,singularityos-lab,singularity-phone,$(SINGULARITY_PHONE_VERSION))
SINGULARITY_PHONE_LICENSE = GPL-3.0+
SINGULARITY_PHONE_LICENSE_FILES = LICENSE
SINGULARITY_PHONE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib

SINGULARITY_PHONE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
