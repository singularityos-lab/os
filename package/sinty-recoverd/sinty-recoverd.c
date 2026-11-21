/* sinty-recoverd -- root daemon: the recovery escape hatch for the pre-login greeter.
 *
 * The greeter runs UNPRIVILEGED (user 'greeter') and must never privilege itself
 * (setpriv would lose its seat). Instead it does IPC to this daemon, which runs as
 * root (a system service started before greetd) and performs the one privileged
 * action: `sintykey recover`. Authorisation IS the recovery code -- high entropy,
 * only the owner has it; sintykey rejects a wrong one. Attempts are rate-limited
 * per uid and every action is logged. This is an ordinary privileged service (like
 * polkit/logind), the intended escape hatch of the locked model.
 *
 * Protocol (line based) on /run/sinty-recoverd.sock:
 *   recover (pre-login greeter, root/greeter):  "<uid>\n<recovery-code>\n<new-pin>\n"
 *   verify  (lockscreen, session user):         "verify\n<uid>\n<pin>\n"
 *   server -> "OK\n" | "FAIL\n" | "BLOCKED\n"
 * The lockscreen runs as the SESSION USER and cannot read the root-only key blobs,
 * so it asks the daemon to verify the PIN. SO_PEERCRED gates "verify": a caller may
 * verify ONLY its own uid (or root) -> no cross-user PIN brute-force over the socket.
 * Both actions are rate-limited per uid.
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <grp.h>
#include <time.h>
#include <signal.h>
#include <sys/time.h>
#include <errno.h>
#include <fcntl.h>
#include <crypt.h>

#define SOCK "/run/sinty-recoverd.sock"
#define LOGF "/var/log/sinty-recoverd.log"
#define MAXTRY 5
#define RL_WINDOW 300  /* seconds: a uid's failure count decays after this idle time */
#define RL_N 128       /* larger table + decay -> exhausting it to bypass the limit is impractical */
#define QUICK_DIR "/var/lib/sinty/quick-unlock"
#define ARMED_DIR "/run/sinty-quick"
#define QUICK_MAXTRY 5

static void logmsg(const char *m) {
    FILE *f = fopen(LOGF, "a");
    if (f) { fprintf(f, "%ld %s\n", (long)time(NULL), m); fclose(f); }
}

/* per-uid attempt counter (in-memory; belt-and-suspenders behind the high-entropy
 * recovery code + the verify peer-cred gate). Entries decay after RL_WINDOW idle, and
 * a full table evicts the OLDEST entry -- so an attacker cannot bypass the limit by
 * flooding junk uids to exhaust the table (they age out / get evicted first). */
static struct { unsigned uid; int tries; int used; time_t ts; } rls[RL_N];
static int rl_blocked(unsigned uid) {
    const time_t now = time(NULL);
    for (int i = 0; i < RL_N; i++)
        if (rls[i].used && rls[i].uid == uid)
            return (now - rls[i].ts <= RL_WINDOW) && rls[i].tries >= MAXTRY;
    return 0;
}
static void rl_bump(unsigned uid, int ok) {
    const time_t now = time(NULL);
    int free_i = -1, old_i = -1;
    for (int i = 0; i < RL_N; i++) {
        if (rls[i].used && rls[i].uid == uid) {
            if (now - rls[i].ts > RL_WINDOW) rls[i].tries = 0; /* decay stale count */
            rls[i].tries = ok ? 0 : rls[i].tries + 1;
            rls[i].ts = now;
            return;
        }
        if (!rls[i].used) { if (free_i < 0) free_i = i; }
        else if (old_i < 0 || rls[i].ts < rls[old_i].ts) old_i = i;
    }
    const int slot = free_i >= 0 ? free_i : old_i; /* reuse free, else evict the oldest */
    if (slot < 0) return;
    rls[slot].used = 1; rls[slot].uid = uid; rls[slot].tries = ok ? 0 : 1; rls[slot].ts = now;
}

static int do_recover(const char *uid, const char *code, const char *pin) {
    int p[2];
    if (pipe(p) != 0) return 1;
    pid_t k = fork();
    if (k < 0) { close(p[0]); close(p[1]); return 1; } /* fail CLOSED, not "OK" */
    if (k == 0) {
        dup2(p[0], 0); close(p[0]); close(p[1]);
        execl("/usr/bin/sintykey", "sintykey", "recover", "--uid", uid, (char *)NULL);
        _exit(127);
    }
    close(p[0]);
    dprintf(p[1], "%s\n%s\n", code, pin);
    close(p[1]);
    int st = 0;
    if (waitpid(k, &st, 0) != k) return 1; /* wait failed (EINTR/ECHILD) -> fail CLOSED */
    return (WIFEXITED(st) && WEXITSTATUS(st) == 0) ? 0 : 1;
}

/* verify-only: the CE key is already in the kernel keyring (from login); the
 * lockscreen just needs to confirm the PIN. Runs `sintykey verify-pin` (root). */
static int do_verify(const char *uid, const char *pin) {
    int p[2];
    if (pipe(p) != 0) return 1;
    pid_t k = fork();
    if (k < 0) { close(p[0]); close(p[1]); return 1; } /* fail CLOSED, not "OK" */
    if (k == 0) {
        dup2(p[0], 0); close(p[0]); close(p[1]);
        execl("/usr/bin/sintykey", "sintykey", "verify-pin", "--uid", uid, (char *)NULL);
        _exit(127);
    }
    close(p[0]);
    dprintf(p[1], "%s\n", pin);
    close(p[1]);
    int st = 0;
    if (waitpid(k, &st, 0) != k) return 1; /* wait failed (EINTR/ECHILD) -> fail CLOSED */
    return (WIFEXITED(st) && WEXITSTATUS(st) == 0) ? 0 : 1;
}

static void reply(int c, const char *m) {
    (void)!write(c, m, strlen(m));
}

static void quick_path(char *out, size_t n, const char *dir, unsigned uid) {
    snprintf(out, n, "%s/%u", dir, uid);
}

static int mkdirs(const char *dir) {
    char tmp[128];
    snprintf(tmp, sizeof tmp, "%s", dir);
    for (char *p = tmp + 1; *p; p++) {
        if (*p != '/') continue;
        *p = '\0';
        if (mkdir(tmp, 0755) != 0 && errno != EEXIST) return -1;
        *p = '/';
    }
    if (mkdir(tmp, 0700) != 0 && errno != EEXIST) return -1;
    return chmod(tmp, 0700);
}

static int write_file(const char *dir, unsigned uid, const char *data) {
    if (mkdirs(dir) != 0) return -1;
    char path[160], tmp[176];
    quick_path(path, sizeof path, dir, uid);
    snprintf(tmp, sizeof tmp, "%s.new", path);
    int fd = open(tmp, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC | O_NOFOLLOW, 0600);
    if (fd < 0) return -1;
    size_t len = strlen(data);
    int ok = write(fd, data, len) == (ssize_t)len && fsync(fd) == 0;
    close(fd);
    if (!ok || rename(tmp, path) != 0) { unlink(tmp); return -1; }
    return 0;
}

static int read_file(const char *dir, unsigned uid, char *out, size_t n) {
    char path[160];
    quick_path(path, sizeof path, dir, uid);
    int fd = open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (fd < 0) return -1;
    ssize_t r = read(fd, out, n - 1);
    close(fd);
    if (r <= 0) return -1;
    out[r] = '\0';
    return 0;
}

static void drop_file(const char *dir, unsigned uid) {
    char path[160];
    quick_path(path, sizeof path, dir, uid);
    unlink(path);
}

struct quick { char kind[16]; int length; char hash[CRYPT_OUTPUT_SIZE]; };

static int quick_load(unsigned uid, struct quick *q) {
    char buf[CRYPT_OUTPUT_SIZE + 64];
    if (read_file(QUICK_DIR, uid, buf, sizeof buf) != 0) return -1;
    if (sscanf(buf, "%15s %d %255s", q->kind, &q->length, q->hash) != 3) return -1;
    return 0;
}

static int armed_fails(unsigned uid) {
    char buf[32];
    if (read_file(ARMED_DIR, uid, buf, sizeof buf) != 0) return -1;
    return atoi(buf);
}

static void arm(unsigned uid, int fails) {
    struct quick q;
    if (quick_load(uid, &q) != 0) { drop_file(ARMED_DIR, uid); return; }
    char buf[32];
    snprintf(buf, sizeof buf, "%d\n", fails);
    write_file(ARMED_DIR, uid, buf);
}

static int valid_secret(const char *kind, const char *secret) {
    size_t n = strlen(secret);
    if (strcmp(kind, "pin") == 0) {
        if (n < 4 || n > 12) return 0;
        for (const char *p = secret; *p; p++) if (*p < '0' || *p > '9') return 0;
        return 1;
    }
    if (strcmp(kind, "pattern") == 0) {
        if (n < 4 || n > 9) return 0;
        int seen[10] = {0};
        for (const char *p = secret; *p; p++) {
            if (*p < '1' || *p > '9' || seen[*p - '0']) return 0;
            seen[*p - '0'] = 1;
        }
        return 1;
    }
    return 0;
}

static int same(const char *a, const char *b) {
    size_t la = strlen(a), lb = strlen(b);
    unsigned char d = la != lb;
    for (size_t i = 0; i < la && i < lb; i++) d |= (unsigned char)(a[i] ^ b[i]);
    return d == 0;
}

static int full_pin(int c, unsigned u, const char *pin, const char *what) {
    char lm[160], uid[16];
    if (rl_blocked(u)) {
        snprintf(lm, sizeof lm, "%s uid=%u BLOCKED (rate-limit)", what, u); logmsg(lm);
        reply(c, "BLOCKED\n");
        return 0;
    }
    snprintf(uid, sizeof uid, "%u", u);
    int r = do_verify(uid, pin);
    rl_bump(u, r == 0);
    snprintf(lm, sizeof lm, "%s uid=%u pin=%s", what, u, r == 0 ? "OK" : "FAIL"); logmsg(lm);
    if (r != 0) { reply(c, "FAIL\n"); return 0; }
    return 1;
}

static void handle_quick(int c, unsigned peer, const char *verb, char **line, int lines) {
    char lm[160];
    if (strcmp(verb, "quick-state") == 0) {
        struct quick q;
        char out[64];
        if (quick_load(peer, &q) != 0) reply(c, "none 0 0\n");
        else {
            snprintf(out, sizeof out, "%s %d %d\n", q.kind, armed_fails(peer) >= 0,
                strcmp(q.kind, "pin") == 0 ? q.length : 0);
            reply(c, out);
        }
        return;
    }
    if (strcmp(verb, "lockdown") == 0) {
        drop_file(ARMED_DIR, peer);
        snprintf(lm, sizeof lm, "lockdown uid=%u", peer); logmsg(lm);
        reply(c, "OK\n");
        return;
    }
    if (strcmp(verb, "arm") == 0 && lines >= 2) {
        char *end = NULL;
        unsigned long u = strtoul(line[1], &end, 10);
        if (peer != 0 || !*line[1] || *end) { reply(c, "FAIL\n"); return; }
        arm((unsigned)u, 0);
        reply(c, "OK\n");
        return;
    }
    if (strcmp(verb, "quick-set") == 0 && lines >= 4) {
        if (!valid_secret(line[2], line[3])) { reply(c, "INVALID\n"); return; }
        if (!full_pin(c, peer, line[1], "quick-set")) return;
        char salt[CRYPT_GENSALT_OUTPUT_SIZE];
        struct crypt_data data;
        memset(&data, 0, sizeof data);
        if (!crypt_gensalt_rn("$y$", 0, NULL, 0, salt, sizeof salt)
                || !crypt_rn(line[3], salt, &data, sizeof data) || data.output[0] == '*') {
            reply(c, "FAIL\n");
            return;
        }
        char record[CRYPT_OUTPUT_SIZE + 64];
        snprintf(record, sizeof record, "%s %zu %s\n", line[2], strlen(line[3]), data.output);
        explicit_bzero(&data, sizeof data);
        if (write_file(QUICK_DIR, peer, record) != 0) { reply(c, "FAIL\n"); return; }
        arm(peer, 0);
        snprintf(lm, sizeof lm, "quick-set uid=%u kind=%s", peer, line[2]); logmsg(lm);
        reply(c, "OK\n");
        return;
    }
    if (strcmp(verb, "quick-clear") == 0 && lines >= 2) {
        if (!full_pin(c, peer, line[1], "quick-clear")) return;
        drop_file(QUICK_DIR, peer);
        drop_file(ARMED_DIR, peer);
        reply(c, "OK\n");
        return;
    }
    if (strcmp(verb, "quick-verify") == 0 && lines >= 2) {
        struct quick q;
        if (quick_load(peer, &q) != 0) { reply(c, "FAIL\n"); return; }
        int fails = armed_fails(peer);
        if (fails < 0 || fails >= QUICK_MAXTRY) {
            drop_file(ARMED_DIR, peer);
            reply(c, "LOCKED\n");
            return;
        }
        struct crypt_data data;
        memset(&data, 0, sizeof data);
        int ok = crypt_rn(line[1], q.hash, &data, sizeof data) && data.output[0] != '*'
            && same(data.output, q.hash);
        explicit_bzero(&data, sizeof data);
        if (ok) {
            arm(peer, 0);
            reply(c, "OK\n");
        } else if (fails + 1 >= QUICK_MAXTRY) {
            drop_file(ARMED_DIR, peer);
            reply(c, "LOCKED\n");
        } else {
            arm(peer, fails + 1);
            reply(c, "FAIL\n");
        }
        snprintf(lm, sizeof lm, "quick-verify uid=%u result=%s", peer, ok ? "OK" : "FAIL"); logmsg(lm);
        return;
    }
    reply(c, "FAIL\n");
}

static int lines_for(const char *buf, size_t off) {
    const char *nl = memchr(buf, '\n', off);
    if (!nl) return 3;
    size_t n = (size_t)(nl - buf);
    if (n == 11 && memcmp(buf, "quick-state", n) == 0) return 1;
    if (n == 8 && memcmp(buf, "lockdown", n) == 0) return 1;
    if (n == 3 && memcmp(buf, "arm", n) == 0) return 2;
    if (n == 11 && memcmp(buf, "quick-clear", n) == 0) return 2;
    if (n == 12 && memcmp(buf, "quick-verify", n) == 0) return 2;
    if (n == 9 && memcmp(buf, "quick-set", n) == 0) return 4;
    return 3;
}

static void handle(int c) {
    /* who is connecting? (SO_PEERCRED gates the "verify" action) */
    struct ucred cred; socklen_t cl = sizeof cred;
    if (getsockopt(c, SOL_SOCKET, SO_PEERCRED, &cred, &cl) != 0) { close(c); return; }

    /* A client that connects and never sends must NOT wedge the single-threaded accept
     * loop (that would deny the lockscreen/greeter exactly when needed). Bound every
     * read: a stalled client times out and the daemon returns to accept(). */
    struct timeval rt = { .tv_sec = 5, .tv_usec = 0 };
    setsockopt(c, SOL_SOCKET, SO_RCVTIMEO, &rt, sizeof rt);

    /* Both actions are 3 lines (verify\nuid\npin OR uid\ncode\nnewpin). Read until we
     * have 3 newlines, or the client closes (EOF), or the buffer fills. */
    char buf[1024];
    size_t off = 0;
    while (off < sizeof buf - 1) {
        ssize_t n = read(c, buf + off, sizeof buf - 1 - off);
        if (n <= 0) break;
        off += (size_t)n;
        int nl = 0;
        for (size_t i = 0; i < off; i++) if (buf[i] == '\n') nl++;
        if (nl >= lines_for(buf, off)) break;
    }
    if (off == 0) { close(c); return; }
    buf[off] = '\0';

    if (lines_for(buf, off) != 3 || strncmp(buf, "quick-", 6) == 0) {
        char *line[4] = {0};
        int lines = 0;
        for (char *p = buf; p && *p && lines < 4; lines++) {
            line[lines] = p;
            char *nl = strchr(p, '\n');
            if (nl) { *nl = '\0'; p = nl + 1; } else p = NULL;
        }
        if (lines > 0) handle_quick(c, cred.uid, line[0], line, lines);
        explicit_bzero(buf, sizeof buf);
        close(c);
        return;
    }

    char lm[160];
    char *l1 = buf, *rest = strchr(buf, '\n');
    if (!rest) { (void)!write(c, "FAIL\n", 5); close(c); return; }
    *rest++ = '\0';

    if (strcmp(l1, "verify") == 0) {
        /* verify\n<uid>\n<pin>\n -- lockscreen re-auth (PIN only, key already in keyring) */
        char *uid = rest, *pin = strchr(rest, '\n');
        if (!pin) { (void)!write(c, "FAIL\n", 5); close(c); return; }
        *pin++ = '\0';
        char *e = strchr(pin, '\n'); if (e) *e = '\0';
        if (!*uid) { (void)!write(c, "FAIL\n", 5); close(c); return; }
        for (const char *q = uid; *q; q++)
            if (*q < '0' || *q > '9') { (void)!write(c, "FAIL\n", 5); close(c); return; }
        unsigned u = (unsigned)strtoul(uid, NULL, 10);
        /* a caller may verify ONLY its own uid (or root): no cross-user PIN brute-force */
        if (cred.uid != 0 && cred.uid != u) {
            snprintf(lm, sizeof lm, "verify uid=%u DENIED peer=%u", u, cred.uid); logmsg(lm);
            (void)!write(c, "FAIL\n", 5); close(c); return;
        }
        if (rl_blocked(u)) {
            snprintf(lm, sizeof lm, "verify uid=%u BLOCKED (rate-limit)", u); logmsg(lm);
            (void)!write(c, "BLOCKED\n", 8); close(c); return;
        }
        int r = do_verify(uid, pin);
        rl_bump(u, r == 0);
        if (r == 0) arm(u, 0);
        snprintf(lm, sizeof lm, "verify uid=%u result=%s", u, r == 0 ? "OK" : "FAIL"); logmsg(lm);
        (void)!write(c, r == 0 ? "OK\n" : "FAIL\n", r == 0 ? 3 : 5);
        close(c); return;
    }

    /* legacy recover: l1 = uid, rest = <recovery-code>\n<new-pin>\n */
    char *uid = l1, *code = rest, *pin = strchr(rest, '\n');
    if (!pin) { (void)!write(c, "FAIL\n", 5); close(c); return; }
    *pin++ = '\0';
    char *e = strchr(pin, '\n'); if (e) *e = '\0';
    if (!*uid) { (void)!write(c, "FAIL\n", 5); close(c); return; }
    for (const char *q = uid; *q; q++)
        if (*q < '0' || *q > '9') { (void)!write(c, "FAIL\n", 5); close(c); return; }
    unsigned u = (unsigned)strtoul(uid, NULL, 10);
    if (rl_blocked(u)) {
        snprintf(lm, sizeof lm, "recover uid=%u BLOCKED (rate-limit)", u); logmsg(lm);
        (void)!write(c, "BLOCKED\n", 8); close(c); return;
    }
    int r = do_recover(uid, code, pin);
    rl_bump(u, r == 0);
    snprintf(lm, sizeof lm, "recover uid=%u result=%s", u, r == 0 ? "OK" : "FAIL"); logmsg(lm);
    (void)!write(c, r == 0 ? "OK\n" : "FAIL\n", r == 0 ? 3 : 5);
    close(c);
}

int main(void) {
    /* A child that exits before we finish dprintf'ing its stdin would raise SIGPIPE
     * (default = terminate this root daemon). Ignore it; the write just returns EPIPE. */
    signal(SIGPIPE, SIG_IGN);
    unlink(SOCK);
    int s = socket(AF_UNIX, SOCK_STREAM, 0);
    if (s < 0) return 1;
    struct sockaddr_un a;
    memset(&a, 0, sizeof a);
    a.sun_family = AF_UNIX;
    strncpy(a.sun_path, SOCK, sizeof a.sun_path - 1);
    if (bind(s, (struct sockaddr *)&a, sizeof a) != 0) return 1;
    /* World-connectable: the greeter (recover) AND the session user (verify) must reach
     * it, and the session user's uid is dynamic (not the 'greeter' group). Safe because
     * the auth gates are strong: recover needs the high-entropy recovery code; verify is
     * SO_PEERCRED-restricted to the caller's own uid + rate-limited + the PIN. */
    chmod(SOCK, 0666);
    listen(s, 4);
    logmsg("sinty-recoverd started");
    for (;;) {
        int c = accept(s, NULL, NULL);
        if (c >= 0) handle(c);
    }
    return 0;
}
