################################################################################
# atom-probe
################################################################################
# The on-device diagnostic probe, fetched as a prebuilt release asset from the
# atom repository (built by its release CI with CGO_ENABLED=0 and trimpath),
# rather than committed as a binary or built from a local path. Fenced at
# runtime by /etc/atom/probe.enabled, which release images strip; this package
# only provides the binary.
ATOM_PROBE_VERSION = v0.1.0
ATOM_PROBE_SITE = https://github.com/singularityos-lab/atom/releases/download/$(ATOM_PROBE_VERSION)
ATOM_PROBE_SOURCE = atom-probe-$(ATOM_PROBE_VERSION)-x86_64.tar.gz
ATOM_PROBE_LICENSE = GPL-3.0-or-later

define ATOM_PROBE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/atom-probe $(TARGET_DIR)/usr/bin/atom-probe
endef

$(eval $(generic-package))
