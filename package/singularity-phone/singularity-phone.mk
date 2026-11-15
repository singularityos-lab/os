################################################################################
#
# singularity-phone
#
################################################################################

SINGULARITY_PHONE_VERSION = 4459209d55a325298116b10445b272263a757a5d
SINGULARITY_PHONE_SITE = $(call github,singularityos-lab,singularity-phone,$(SINGULARITY_PHONE_VERSION))
SINGULARITY_PHONE_LICENSE = GPL-3.0+
SINGULARITY_PHONE_LICENSE_FILES = LICENSE
SINGULARITY_PHONE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib

SINGULARITY_PHONE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
