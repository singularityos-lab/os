################################################################################
#
# sinty-matrix
#
################################################################################

SINTY_MATRIX_VERSION = 80f22cfa2583ef9e1e93766775c81467bdfbff99
SINTY_MATRIX_SITE = $(call github,singularityos-lab,sinty-matrix,$(SINTY_MATRIX_VERSION))
SINTY_MATRIX_LICENSE = GPL-3.0-only
SINTY_MATRIX_LICENSE_FILES = LICENSE
SINTY_MATRIX_CPU = $(if $(BR2_x86_64),x86_64_v2,baseline)

define SINTY_MATRIX_BUILD_CMDS
	cd $(@D) && $(TARGET_MAKE_ENV) zig build -Doptimize=ReleaseSafe \
		-Dtarget=$(BR2_ARCH)-linux-musl \
		-Dcpu=$(SINTY_MATRIX_CPU) \
		-Dstrip=true \
		--prefix $(@D)/out
endef

define SINTY_MATRIX_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/out/libexec/sinty-matrixd $(TARGET_DIR)/usr/libexec/sinty-matrixd
	$(INSTALL) -D -m 0755 $(@D)/out/bin/sinty-matrixctl $(TARGET_DIR)/usr/bin/sinty-matrixctl
	$(INSTALL) -D -m 0644 $(@D)/out/share/sinty-matrix/uno-q.bin $(TARGET_DIR)/usr/share/sinty-matrix/uno-q.bin
	$(INSTALL) -D -m 0644 $(@D)/data/devices/arduino,imola.conf $(TARGET_DIR)/usr/share/sinty-matrix/devices/arduino,imola.conf
	$(INSTALL) -D -m 0644 $(@D)/data/sinty-matrixd.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-matrixd.service
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/graphical.target.wants
	ln -sf /usr/lib/systemd/system/sinty-matrixd.service $(TARGET_DIR)/usr/lib/systemd/system/graphical.target.wants/sinty-matrixd.service
endef

$(eval $(generic-package))
