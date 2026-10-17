################################################################################
#
# uutils-coreutils
#
################################################################################

UUTILS_COREUTILS_VERSION = 0.12.0
UUTILS_COREUTILS_SITE = $(call github,uutils,coreutils,$(UUTILS_COREUTILS_VERSION))
UUTILS_COREUTILS_LICENSE = MIT
UUTILS_COREUTILS_LICENSE_FILES = LICENSE
UUTILS_COREUTILS_CARGO_BUILD_OPTS = --no-default-features --features unix --bin coreutils

UUTILS_COREUTILS_PROGS = \
	arch b2sum base32 base64 basename basenc cat chgrp chmod chown chroot \
	cksum comm cp csplit cut date dd df dir dircolors dirname du echo env \
	expand expr factor false fmt fold groups head hostid hostname id \
	install join kill link ln logname ls md5sum mkdir mkfifo mknod mktemp \
	more mv nice nl nohup nproc numfmt od paste pathchk pinky pr printenv \
	printf ptx pwd readlink realpath rm rmdir seq sha1sum sha224sum \
	sha256sum sha384sum sha512sum shred shuf sleep sort split stat stdbuf \
	stty sum sync tac tail tee test timeout touch tr true truncate tsort \
	tty uname unexpand uniq unlink uptime users vdir wc who whoami yes

define UUTILS_COREUTILS_INSTALL_TARGET_CMDS
	find $(TARGET_DIR)/usr/bin $(TARGET_DIR)/usr/sbin -maxdepth 1 -type l -lname '*coreutils' -delete
	$(INSTALL) -D -m 0755 $(@D)/target/$(RUSTC_TARGET_NAME)/release/coreutils \
		$(TARGET_DIR)/usr/bin/coreutils
	for p in $(UUTILS_COREUTILS_PROGS); do \
		ln -sf coreutils $(TARGET_DIR)/usr/bin/$$p || exit 1; \
	done
	ln -sf test $(TARGET_DIR)/usr/bin/[
endef

$(eval $(cargo-package))
