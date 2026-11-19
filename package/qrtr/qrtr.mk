################################################################################
#
# qrtr
#
################################################################################

QRTR_VERSION = 29e36ae164389580a0f8ea7a7fdb728140ae978d
QRTR_SITE = $(call github,linux-msm,qrtr,$(QRTR_VERSION))
QRTR_LICENSE = BSD-3-Clause
QRTR_LICENSE_FILES = LICENSE
QRTR_INSTALL_STAGING = YES
QRTR_DEPENDENCIES = host-pkgconf

$(eval $(meson-package))
