################################################################################
#
# cargo-c
#
################################################################################

CARGO_C_VERSION = 0.10.16+cargo-0.91.0
CARGO_C_SITE = https://static.crates.io/crates/cargo-c
CARGO_C_SOURCE = cargo-c-$(CARGO_C_VERSION).crate
CARGO_C_LICENSE = MIT
CARGO_C_LICENSE_FILES = LICENSE
HOST_CARGO_C_DEPENDENCIES = host-pkgconf host-openssl host-zlib

define HOST_CARGO_C_EXTRACT_CMDS
	$(TAR) -xzf $(HOST_CARGO_C_DL_DIR)/$(CARGO_C_SOURCE) --strip-components=1 -C $(@D)
endef

$(eval $(host-cargo-package))
