/* SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2026 Mirko Brombin <brombin94@gmail.com>
 *
 * libsystemd shim for Singularity OS under sinit.
 *
 * When systemd is removed, nothing provides libsystemd.so.0, yet many binaries
 * (NetworkManager, xdg-desktop-portal, WebKit, pulseaudio, the shadow suite,
 * accountsservice, dbus-daemon) link its sd_* symbols. This shim provides that
 * ABI without systemd, backed by what we actually run:
 *
 *   (c) sd-daemon / journal / id128  -> sinit + our syslogd + /etc/machine-id  [REAL here]
 *   (b) sd-login (session/seat/uid)  -> seatd + pam_rundir                     [stub -> real, M3]
 *   (a) sd-bus                       -> the real dbus-daemon via libdbus-1      [stub -> real, M2]
 *
 * Milestone 1 (this file): the full versioned ABI so every consumer LINKS and
 * LOADS, with group (c) functional. sd-login returns "no data" (the same as a
 * running system with no logind, which consumers already tolerate) and sd-bus
 * reports unavailable. M2 wires sd-bus onto libdbus-1; M3 wires sd-login onto
 * seatd so polkit sees an active session again.
 */

#define _GNU_SOURCE
#include <errno.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <dirent.h>
#include <sys/eventfd.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <sys/un.h>

/* ─────────────────────────── (c) sd-daemon ─────────────────────────── */

int sd_listen_fds(int unset_environment) {
	const char *pid = getenv("LISTEN_PID");
	const char *fds = getenv("LISTEN_FDS");
	int n = 0;
	if (pid && strtol(pid, NULL, 10) == (long)getpid() && fds) {
		long v = strtol(fds, NULL, 10);
		n = (v > 0) ? (int)v : 0;
	}
	if (unset_environment) {
		unsetenv("LISTEN_PID");
		unsetenv("LISTEN_FDS");
		unsetenv("LISTEN_FDNAMES");
	}
	return n;
}

int sd_notify(int unset_environment, const char *state) {
	const char *path = getenv("NOTIFY_SOCKET");
	int r;
	if (!path) {
		return 0; /* no notify socket: nothing to do */
	}
	if (!state || !*state) {
		r = 1;
	} else {
		int fd = socket(AF_UNIX, SOCK_DGRAM | SOCK_CLOEXEC, 0);
		if (fd < 0) {
			r = -errno;
		} else {
			struct sockaddr_un sa;
			size_t l = strlen(path);
			memset(&sa, 0, sizeof sa);
			sa.sun_family = AF_UNIX;
			if (l >= sizeof sa.sun_path) {
				close(fd);
				return -EINVAL;
			}
			memcpy(sa.sun_path, path, l + 1);
			if (sa.sun_path[0] == '@') {
				sa.sun_path[0] = '\0'; /* abstract namespace */
			}
			ssize_t w = sendto(fd, state, strlen(state), MSG_NOSIGNAL,
			                   (struct sockaddr *)&sa,
			                   offsetof(struct sockaddr_un, sun_path) + l);
			r = (w < 0) ? -errno : 1;
			close(fd);
		}
	}
	if (unset_environment) {
		unsetenv("NOTIFY_SOCKET");
	}
	return r;
}

int sd_booted(void) {
	return 1; /* there IS a system manager (sinit), just not systemd */
}

int sd_is_socket(int fd, int family, int type, int listening) {
	struct stat st;
	if (fstat(fd, &st) < 0)
		return -errno;
	if (!S_ISSOCK(st.st_mode))
		return 0;
	if (family > 0) {
		int f;
		socklen_t l = sizeof f;
		if (getsockopt(fd, SOL_SOCKET, SO_DOMAIN, &f, &l) < 0)
			return -errno;
		if (f != family)
			return 0;
	}
	if (type > 0) {
		int t;
		socklen_t l = sizeof t;
		if (getsockopt(fd, SOL_SOCKET, SO_TYPE, &t, &l) < 0)
			return -errno;
		if (t != type)
			return 0;
	}
	if (listening >= 0) {
		int a;
		socklen_t l = sizeof a;
		if (getsockopt(fd, SOL_SOCKET, SO_ACCEPTCONN, &a, &l) < 0)
			return -errno;
		if (!!a != !!listening)
			return 0;
	}
	return 1;
}

int sd_is_socket_inet(int fd, int family, int type, int listening, uint16_t port) {
	(void)port;
	return sd_is_socket(fd, family, type, listening);
}

int sd_is_socket_unix(int fd, int type, int listening, const char *path, size_t length) {
	(void)path;
	(void)length;
	return sd_is_socket(fd, AF_UNIX, type, listening);
}

/* ─────────────────────────── (c) sd-journal ────────────────────────── */
/* Backed by our syslogd on /dev/log: format "<PRI>message" and send it. */

#define SHIM_LOG_DEFAULT 6 /* LOG_INFO */

static void journal_emit(int priority, const char *msg, size_t len) {
	if (!msg)
		return;
	int fd = socket(AF_UNIX, SOCK_DGRAM | SOCK_CLOEXEC, 0);
	if (fd < 0)
		return;
	struct sockaddr_un sa;
	memset(&sa, 0, sizeof sa);
	sa.sun_family = AF_UNIX;
	strncpy(sa.sun_path, "/dev/log", sizeof sa.sun_path - 1);
	char hdr[16];
	int hl = snprintf(hdr, sizeof hdr, "<%d>", (priority & 7) | (1 << 3)); /* user facility */
	struct iovec iov[2] = {
		{hdr, (size_t)hl},
		{(void *)msg, len},
	};
	struct msghdr mh;
	memset(&mh, 0, sizeof mh);
	mh.msg_name = &sa;
	mh.msg_namelen = sizeof sa;
	mh.msg_iov = iov;
	mh.msg_iovlen = 2;
	(void)sendmsg(fd, &mh, MSG_NOSIGNAL);
	close(fd);
}

int sd_journal_sendv(const struct iovec *iov, int n) {
	int priority = SHIM_LOG_DEFAULT;
	const char *msg = NULL;
	size_t msglen = 0;
	for (int i = 0; i < n; i++) {
		const char *b = iov[i].iov_base;
		size_t l = iov[i].iov_len;
		if (l > 8 && strncmp(b, "MESSAGE=", 8) == 0) {
			msg = b + 8;
			msglen = l - 8;
		} else if (l > 9 && strncmp(b, "PRIORITY=", 9) == 0) {
			priority = atoi(b + 9);
		}
	}
	if (msg)
		journal_emit(priority, msg, msglen);
	return 0;
}

int sd_journal_printv_with_location(int priority, const char *file, const char *line,
                                    const char *func, const char *format, va_list ap) {
	(void)file;
	(void)line;
	(void)func;
	char buf[2048];
	int l = vsnprintf(buf, sizeof buf, format, ap);
	if (l < 0)
		return -EINVAL;
	journal_emit(priority, buf, (size_t)((l < (int)sizeof buf) ? l : (int)sizeof buf - 1));
	return 0;
}

/* The MESSAGE=... field-list variadic forms are hard to parse safely without
 * knowing each format's arg count; log the first field best-effort and drop the
 * rest rather than risk a bad va_arg walk. Non-fatal: the service still runs. */
static int journal_send_first(const char *format, va_list ap) {
	if (!format)
		return 0;
	char buf[2048];
	int l = vsnprintf(buf, sizeof buf, format, ap);
	if (l < 0)
		return 0;
	const char *m = buf;
	if (strncmp(buf, "MESSAGE=", 8) == 0)
		m = buf + 8;
	journal_emit(SHIM_LOG_DEFAULT, m, strlen(m));
	return 0;
}

int sd_journal_send(const char *format, ...) {
	va_list ap;
	va_start(ap, format);
	int r = journal_send_first(format, ap);
	va_end(ap);
	return r;
}

int sd_journal_send_with_location(const char *file, const char *line, const char *func,
                                  const char *format, ...) {
	(void)file;
	(void)line;
	(void)func;
	va_list ap;
	va_start(ap, format);
	int r = journal_send_first(format, ap);
	va_end(ap);
	return r;
}

int sd_journal_stream_fd(const char *identifier, int priority, int level_prefix) {
	(void)identifier;
	(void)priority;
	(void)level_prefix;
	/* Callers write newline-delimited log text here. A pipe pump to /dev/log is
	 * an M2 refinement; for now hand back a writable fd that never blocks. */
	int fd = open("/dev/null", O_WRONLY | O_CLOEXEC);
	return fd < 0 ? -errno : fd;
}

/* ─────────────────────────── (c) sd-id128 ──────────────────────────── */

typedef union {
	uint8_t bytes[16];
	uint64_t qwords[2];
} sd_id128_t;

static int read_machine_id(uint8_t out[16]) {
	int fd = open("/etc/machine-id", O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -errno;
	char hex[33];
	ssize_t r = read(fd, hex, 32);
	close(fd);
	if (r < 32)
		return -EIO;
	hex[32] = 0;
	for (int i = 0; i < 16; i++) {
		unsigned v;
		if (sscanf(hex + 2 * i, "%2x", &v) != 1)
			return -EINVAL;
		out[i] = (uint8_t)v;
	}
	return 0;
}

int sd_id128_get_machine_app_specific(sd_id128_t app_id, sd_id128_t *ret) {
	uint8_t m[16];
	int r = read_machine_id(m);
	if (r < 0)
		return r;
	/* Stable per (machine, app) derivation. Not byte-compatible with systemd's
	 * HMAC-SHA256 (we avoid a libcrypto dependency), but consumers only need a
	 * stable, app-distinct 128-bit id, which this provides. */
	uint8_t o[16];
	for (int i = 0; i < 16; i++)
		o[i] = m[i] ^ app_id.bytes[i] ^ (uint8_t)(m[(i + 7) % 16] * 31 + app_id.bytes[(i + 5) % 16]);
	o[6] = (o[6] & 0x0F) | 0x40; /* version 4 */
	o[8] = (o[8] & 0x3F) | 0x80; /* variant */
	if (ret)
		memcpy(ret->bytes, o, 16);
	return 0;
}

/* ─────────────────────────── (b) sd-login ──────────────────────────── */
/* Backed by a tiny /run session registry the session-start path writes
 * (/run/sinty/session-<id> with lines uid=, seat=, vt=, class=, type=, display=)
 * plus the live foreground VT (/sys/class/tty/tty0/active). "Active" is computed,
 * not stored: a session is active iff its VT is the foreground one. No logind, no
 * daemon -- this is what makes polkit see an active session again. */

#define SINTY_SESSION_DIR "/run/sinty"

static int foreground_vt(void) {
	int fd = open("/sys/class/tty/tty0/active", O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -1;
	char buf[32];
	ssize_t r = read(fd, buf, sizeof buf - 1);
	close(fd);
	if (r <= 0)
		return -1;
	buf[r] = 0;
	int vt = -1;
	return sscanf(buf, "tty%d", &vt) == 1 ? vt : -1;
}

static int session_field(const char *id, const char *key, char *out, size_t n) {
	char path[256];
	snprintf(path, sizeof path, SINTY_SESSION_DIR "/session-%s", id);
	FILE *f = fopen(path, "re");
	if (!f)
		return -ENOENT;
	char line[512];
	size_t kl = strlen(key);
	int r = -ENOENT;
	while (fgets(line, sizeof line, f)) {
		if (strncmp(line, key, kl) == 0 && line[kl] == '=') {
			char *v = line + kl + 1, *e = v + strlen(v);
			while (e > v && (e[-1] == '\n' || e[-1] == '\r'))
				*--e = 0;
			snprintf(out, n, "%s", v);
			r = 0;
			break;
		}
	}
	fclose(f);
	return r;
}

static int session_exists(const char *id) {
	char path[256];
	snprintf(path, sizeof path, SINTY_SESSION_DIR "/session-%s", id);
	return access(path, F_OK) == 0;
}

static char *dup_field(const char *id, const char *key) {
	char v[256];
	return session_field(id, key, v, sizeof v) == 0 ? strdup(v) : NULL;
}

static uid_t session_uid(const char *id, int *ok) {
	char path[256];
	snprintf(path, sizeof path, SINTY_SESSION_DIR "/session-%s", id);
	struct stat st;
	if (stat(path, &st) < 0) {
		if (ok) *ok = 0;
		return (uid_t)-1;
	}
	if (ok) *ok = 1;
	/* Security: the file's OWNER is authoritative, NOT the uid= field. In a
	 * world-writable /run/sinty a non-root user cannot forge uid=0 -- a file they
	 * create is owned by them, so they can only assert their own uid (and never
	 * root). Only a root writer (pam_rundir/greetd, owner 0) is trusted to name
	 * the uid via uid= on behalf of a user. This defuses the polkit-active
	 * escalation regardless of the directory mode. */
	if (st.st_uid != 0)
		return st.st_uid;
	char v[32];
	if (session_field(id, "uid", v, sizeof v) == 0)
		return (uid_t)strtoul(v, NULL, 10);
	return 0;
}

int sd_session_is_active(const char *session) {
	if (!session || !session_exists(session))
		return -ENXIO;
	char v[32];
	if (session_field(session, "vt", v, sizeof v) < 0)
		return 0;
	int fg = foreground_vt();
	return (fg >= 0 && atoi(v) == fg) ? 1 : 0;
}

int sd_session_get_state(const char *session, char **state) {
	if (!session || !session_exists(session))
		return -ENXIO;
	if (state)
		*state = strdup(sd_session_is_active(session) == 1 ? "active" : "online");
	return 0;
}

int sd_session_get_uid(const char *session, uid_t *uid) {
	int ok = 0;
	uid_t u = session ? session_uid(session, &ok) : (uid_t)-1;
	if (!ok)
		return -ENXIO;
	if (uid)
		*uid = u;
	return 0;
}

#define SESSION_STR_GETTER(fn, field)                                    \
	int fn(const char *session, char **out) {                        \
		char *s = session ? dup_field(session, field) : NULL;    \
		if (!s)                                                  \
			return -ENXIO;                                   \
		if (out) *out = s; else free(s);                         \
		return 0;                                                \
	}
SESSION_STR_GETTER(sd_session_get_seat, "seat")
SESSION_STR_GETTER(sd_session_get_type, "type")
SESSION_STR_GETTER(sd_session_get_class, "class")
SESSION_STR_GETTER(sd_session_get_display, "display")

int sd_session_get_remote_host(const char *session, char **remote_host) {
	(void)session;
	if (remote_host) *remote_host = NULL;
	return -ENODATA; /* local sessions only */
}
int sd_seat_can_multi_session(const char *seat) { (void)seat; return 1; }

/* Iterate the registry; cb(id, ctx) returns <0 to stop early. */
typedef int (*session_cb)(const char *id, void *ctx);
static int for_each_session(session_cb cb, void *ctx) {
	DIR *d = opendir(SINTY_SESSION_DIR);
	if (!d)
		return -ENOENT;
	struct dirent *de;
	int rc = 0;
	while ((de = readdir(d))) {
		if (strncmp(de->d_name, "session-", 8) == 0 && (rc = cb(de->d_name + 8, ctx)) < 0)
			break;
	}
	closedir(d);
	return rc;
}

struct collector {
	char **items;
	size_t n, cap;
	uid_t uid;
	int use_uid, require_active;
	const char *field; /* collect this field's value instead of the id, or NULL */
};

static int coll_push(struct collector *c, const char *s) {
	for (size_t i = 0; i < c->n; i++)
		if (strcmp(c->items[i], s) == 0)
			return 0; /* dedup */
	if (c->n + 2 > c->cap) {
		size_t nc = c->cap ? c->cap * 2 : 8;
		char **ni = realloc(c->items, nc * sizeof(char *));
		if (!ni)
			return -ENOMEM;
		c->items = ni;
		c->cap = nc;
	}
	c->items[c->n] = strdup(s);
	return c->items[c->n] ? (c->n++, 0) : -ENOMEM;
}

static int coll_cb(const char *id, void *ctx) {
	struct collector *c = ctx;
	if (c->use_uid) {
		int ok = 0;
		if (session_uid(id, &ok) != c->uid || !ok)
			return 0;
	}
	if (c->require_active && sd_session_is_active(id) != 1)
		return 0;
	if (c->field) {
		char v[256];
		return session_field(id, c->field, v, sizeof v) == 0 ? coll_push(c, v) : 0;
	}
	return coll_push(c, id);
}

static int coll_finish(struct collector *c, char ***out) {
	if (c->n == 0) {
		free(c->items);
		if (out) *out = NULL;
		return 0;
	}
	c->items[c->n] = NULL; /* room reserved by coll_push (+2) */
	if (out)
		*out = c->items;
	else {
		for (size_t i = 0; i < c->n; i++)
			free(c->items[i]);
		free(c->items);
	}
	return (int)c->n;
}

int sd_get_sessions(char ***sessions) {
	struct collector c = {0};
	for_each_session(coll_cb, &c);
	return coll_finish(&c, sessions);
}
int sd_uid_get_sessions(uid_t uid, int require_active, char ***sessions) {
	struct collector c = {.use_uid = 1, .uid = uid, .require_active = require_active};
	for_each_session(coll_cb, &c);
	return coll_finish(&c, sessions);
}
int sd_uid_get_seats(uid_t uid, int require_active, char ***seats) {
	struct collector c = {.use_uid = 1, .uid = uid, .require_active = require_active, .field = "seat"};
	for_each_session(coll_cb, &c);
	return coll_finish(&c, seats);
}

struct match_ctx {
	uid_t uid;
	int require_active;
	const char *seat; /* for is_on_seat */
	char *found_id;   /* for pid/display lookups */
	int found;
};

static int on_seat_cb(const char *id, void *ctx) {
	struct match_ctx *m = ctx;
	int ok = 0;
	if (session_uid(id, &ok) != m->uid || !ok)
		return 0;
	if (m->require_active && sd_session_is_active(id) != 1)
		return 0;
	char v[256];
	if (session_field(id, "seat", v, sizeof v) == 0 && strcmp(v, m->seat) == 0)
		m->found = 1;
	return 0;
}
int sd_uid_is_on_seat(uid_t uid, int require_active, const char *seat) {
	if (!seat)
		return -EINVAL;
	struct match_ctx m = {.uid = uid, .require_active = require_active, .seat = seat};
	for_each_session(on_seat_cb, &m);
	return m.found;
}

static int display_cb(const char *id, void *ctx) {
	struct match_ctx *m = ctx;
	if (m->found_id)
		return 0;
	int ok = 0;
	if (session_uid(id, &ok) != m->uid || !ok)
		return 0;
	char v[256];
	if (session_field(id, "display", v, sizeof v) == 0)
		m->found_id = strdup(id);
	return 0;
}
int sd_uid_get_display(uid_t uid, char **session) {
	struct match_ctx m = {.uid = uid};
	for_each_session(display_cb, &m);
	if (!m.found_id)
		return -ENODATA;
	if (session) *session = m.found_id; else free(m.found_id);
	return 0;
}

/* pid -> uid (via /proc ownership) -> that uid's session, preferring the active
 * one. Good enough for polkit, which asks for the requesting process's session. */
static int pid_session_cb(const char *id, void *ctx) {
	struct match_ctx *m = ctx;
	int ok = 0;
	if (session_uid(id, &ok) != m->uid || !ok)
		return 0;
	if (sd_session_is_active(id) == 1) {
		free(m->found_id);
		m->found_id = strdup(id);
		return -1; /* active session found: stop */
	}
	if (!m->found_id)
		m->found_id = strdup(id);
	return 0;
}
int sd_pid_get_session(pid_t pid, char **session) {
	char path[64];
	struct stat st;
	snprintf(path, sizeof path, "/proc/%d", (int)pid);
	if (stat(path, &st) < 0)
		return -ENXIO;
	struct match_ctx m = {.uid = st.st_uid};
	for_each_session(pid_session_cb, &m);
	if (!m.found_id)
		return -ENODATA;
	if (session) *session = m.found_id; else free(m.found_id);
	return 0;
}
int sd_pid_get_user_unit(pid_t pid, char **unit) { (void)pid; if (unit) *unit = NULL; return -ENODATA; }
int sd_pid_get_user_slice(pid_t pid, char **slice) { (void)pid; if (slice) *slice = NULL; return -ENODATA; }

typedef struct sd_login_monitor sd_login_monitor;

int sd_login_monitor_new(const char *category, sd_login_monitor **ret) {
	(void)category;
	/* An inert monitor: a valid, never-signalled eventfd so callers can poll it
	 * without special-casing and simply never see a change. */
	int fd = eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);
	if (fd < 0)
		return -errno;
	int *m = malloc(sizeof(int));
	if (!m) {
		close(fd);
		return -ENOMEM;
	}
	*m = fd;
	if (ret)
		*ret = (sd_login_monitor *)m;
	return 0;
}

sd_login_monitor *sd_login_monitor_unref(sd_login_monitor *m) {
	if (m) {
		int *p = (int *)m;
		close(*p);
		free(p);
	}
	return NULL;
}

int sd_login_monitor_flush(sd_login_monitor *m) { (void)m; return 0; }
int sd_login_monitor_get_fd(sd_login_monitor *m) { return m ? *(int *)m : -EINVAL; }

/* ─────────────────────────── (a) sd-bus ────────────────────────────── */
/* M1 stub: reports the bus unavailable. M2 backs these onto libdbus-1 talking
 * to the real dbus-daemon (which we keep), so on-demand and property calls work.
 * The unref/free forms are safe no-ops so cleanup paths never crash. */

typedef struct sd_bus sd_bus;
typedef struct sd_bus_message sd_bus_message;
typedef struct sd_bus_slot sd_bus_slot;
typedef struct {
	const char *name;
	const char *message;
	int _need_free;
} sd_bus_error;
typedef int (*sd_bus_message_handler_t)(sd_bus_message *m, void *userdata, sd_bus_error *ret_error);

int sd_bus_default_system(sd_bus **ret) { (void)ret; return -ENOSYS; }
sd_bus *sd_bus_unref(sd_bus *bus) { (void)bus; return NULL; }
int sd_bus_get_fd(sd_bus *bus) { (void)bus; return -ENOSYS; }
int sd_bus_process(sd_bus *bus, sd_bus_message **ret) { (void)bus; if (ret) *ret = NULL; return -ENOSYS; }
int sd_bus_get_n_queued_read(sd_bus *bus, uint64_t *ret) { (void)bus; if (ret) *ret = 0; return 0; }
int sd_bus_get_n_queued_write(sd_bus *bus, uint64_t *ret) { (void)bus; if (ret) *ret = 0; return 0; }
void sd_bus_error_free(sd_bus_error *e) { (void)e; }

int sd_bus_call_method(sd_bus *bus, const char *destination, const char *path,
                       const char *interface, const char *member, sd_bus_error *ret_error,
                       sd_bus_message **reply, const char *types, ...) {
	(void)bus; (void)destination; (void)path; (void)interface; (void)member;
	(void)ret_error; (void)types;
	if (reply) *reply = NULL;
	return -ENOSYS;
}

int sd_bus_call_method_async(sd_bus *bus, sd_bus_slot **slot, const char *destination,
                             const char *path, const char *interface, const char *member,
                             sd_bus_message_handler_t callback, void *userdata,
                             const char *types, ...) {
	(void)bus; (void)destination; (void)path; (void)interface; (void)member;
	(void)callback; (void)userdata; (void)types;
	if (slot) *slot = NULL;
	return -ENOSYS;
}

int sd_bus_get_property_trivial(sd_bus *bus, const char *destination, const char *path,
                                const char *interface, const char *member,
                                sd_bus_error *ret_error, char type, void *ret_ptr) {
	(void)bus; (void)destination; (void)path; (void)interface; (void)member;
	(void)ret_error; (void)type; (void)ret_ptr;
	return -ENOSYS;
}

int sd_bus_match_signal(sd_bus *bus, sd_bus_slot **ret, const char *sender, const char *path,
                        const char *interface, const char *member,
                        sd_bus_message_handler_t callback, void *userdata) {
	(void)bus; (void)sender; (void)path; (void)interface; (void)member;
	(void)callback; (void)userdata;
	if (ret) *ret = NULL;
	return -ENOSYS;
}

sd_bus_message *sd_bus_message_unref(sd_bus_message *m) { (void)m; return NULL; }
int sd_bus_message_read_basic(sd_bus_message *m, char type, void *p) { (void)m; (void)type; (void)p; return -ENOSYS; }
int sd_bus_message_read(sd_bus_message *m, const char *types, ...) { (void)m; (void)types; return -ENOSYS; }
int sd_bus_message_skip(sd_bus_message *m, const char *types) { (void)m; (void)types; return -ENOSYS; }
int sd_bus_message_enter_container(sd_bus_message *m, char type, const char *contents) { (void)m; (void)type; (void)contents; return -ENOSYS; }
int sd_bus_message_exit_container(sd_bus_message *m) { (void)m; return -ENOSYS; }
const sd_bus_error *sd_bus_message_get_error(sd_bus_message *m) { (void)m; return NULL; }
int sd_bus_message_is_method_error(sd_bus_message *m, const char *name) { (void)m; (void)name; return 0; }
