################################################################################
#
# singularity-vector
#
################################################################################

SINGULARITY_VECTOR_VERSION = b5e0131592d6959cde4c7d2783473f5c76466ffb
SINGULARITY_VECTOR_SITE = $(call github,singularityos-lab,singularity-vector,$(SINGULARITY_VECTOR_VERSION))
SINGULARITY_VECTOR_LICENSE = GPL-3.0+
SINGULARITY_VECTOR_LICENSE_FILES = LICENSE
SINGULARITY_VECTOR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib lcms2 libpeas2 tiff libxml2 pango zlib

SINGULARITY_VECTOR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
