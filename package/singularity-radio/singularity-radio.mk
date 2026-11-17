################################################################################
#
# singularity-radio
#
################################################################################

SINGULARITY_RADIO_VERSION = ba043a750d4df8b2f1c9d23b273ac64e21b513f5
SINGULARITY_RADIO_SITE = $(call github,singularityos-lab,singularity-radio,$(SINGULARITY_RADIO_VERSION))
SINGULARITY_RADIO_LICENSE = GPL-3.0+
SINGULARITY_RADIO_LICENSE_FILES = LICENSE
SINGULARITY_RADIO_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base json-glib libsoup3

SINGULARITY_RADIO_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
