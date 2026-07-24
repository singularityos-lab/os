################################################################################
#
# sinty-timedate
#
################################################################################

SINTY_TIMEDATE_VERSION = local
SINTY_TIMEDATE_SITE = /home/mirko/Projects/personal/sinty-timedate
SINTY_TIMEDATE_SITE_METHOD = local
# The repo ships no LICENSE file yet (GPL-3.0 selected for sinty-sdb; not yet
# stated for this one). Declaring one we were not given would be a claim, so
# leave it unset and add LICENSE + LICENSE_FILES once confirmed.
SINTY_TIMEDATE_LICENSE = NOT-SPECIFIED

SINTY_TIMEDATE_GOMOD = github.com/singularityos-lab/sinty-timedate
SINTY_TIMEDATE_BUILD_TARGETS = cmd/sinty-timedate

define SINTY_TIMEDATE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-timedate $(TARGET_DIR)/usr/bin/sinty-timedate
endef

$(eval $(golang-package))
