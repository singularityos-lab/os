################################################################################
#
# singularity-radio
#
################################################################################

SINGULARITY_RADIO_VERSION = e9415e35778c7b85688acadcfee84e1c986b6338
SINGULARITY_RADIO_SITE = $(call github,singularityos-lab,singularity-radio,$(SINGULARITY_RADIO_VERSION))
SINGULARITY_RADIO_LICENSE = GPL-3.0+
SINGULARITY_RADIO_LICENSE_FILES = LICENSE
SINGULARITY_RADIO_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base json-glib libsoup3

SINGULARITY_RADIO_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
