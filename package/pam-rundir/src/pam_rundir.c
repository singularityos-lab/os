#include <security/pam_modules.h>
#include <security/pam_ext.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <syslog.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int provide_rundir(pam_handle_t *pamh)
{
	const char *user = NULL;
	if (pam_get_user(pamh, &user, NULL) != PAM_SUCCESS || user == NULL)
		return PAM_SESSION_ERR;

	struct passwd *pw = getpwnam(user);
	if (pw == NULL)
		return PAM_SESSION_ERR;

	char path[64];
	snprintf(path, sizeof(path), "/run/user/%lu", (unsigned long)pw->pw_uid);

	mkdir("/run/user", 0755);
	if (mkdir(path, 0700) != 0 && errno != EEXIST) {
		pam_syslog(pamh, LOG_ERR, "pam_rundir: mkdir %s failed: %m", path);
		return PAM_SESSION_ERR;
	}
	if (chown(path, pw->pw_uid, pw->pw_gid) != 0)
		pam_syslog(pamh, LOG_WARNING, "pam_rundir: chown %s failed: %m", path);
	chmod(path, 0700);

	char env[128];
	snprintf(env, sizeof(env), "XDG_RUNTIME_DIR=%s", path);
	if (pam_putenv(pamh, env) != PAM_SUCCESS)
		return PAM_SESSION_ERR;

	return PAM_SUCCESS;
}

PAM_EXTERN int pam_sm_open_session(pam_handle_t *pamh, int flags, int argc, const char **argv)
{
	(void)flags; (void)argc; (void)argv;
	return provide_rundir(pamh);
}

PAM_EXTERN int pam_sm_close_session(pam_handle_t *pamh, int flags, int argc, const char **argv)
{
	(void)pamh; (void)flags; (void)argc; (void)argv;
	return PAM_SUCCESS;
}
