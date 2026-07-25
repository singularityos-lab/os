PAM_RUNDIR_VERSION = local
PAM_RUNDIR_SITE = $(BR2_EXTERNAL_SINGULARITY_PATH)/package/pam-rundir/src
PAM_RUNDIR_SITE_METHOD = local
PAM_RUNDIR_LICENSE = GPL-3.0-or-later
PAM_RUNDIR_DEPENDENCIES = linux-pam

define PAM_RUNDIR_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) -fPIC -shared -o $(@D)/pam_rundir.so $(@D)/pam_rundir.c -lpam
endef

define PAM_RUNDIR_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/pam_rundir.so $(TARGET_DIR)/usr/lib/security/pam_rundir.so
endef

$(eval $(generic-package))
