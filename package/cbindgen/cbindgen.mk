################################################################################
#
# cbindgen
#
################################################################################

CBINDGEN_VERSION = 0.29.4
CBINDGEN_SITE = $(call github,mozilla,cbindgen,v$(CBINDGEN_VERSION))
CBINDGEN_LICENSE = MPL-2.0
CBINDGEN_LICENSE_FILES = LICENSE

$(eval $(host-cargo-package))
