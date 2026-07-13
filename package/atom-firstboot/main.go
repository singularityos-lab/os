// atom-firstboot: first-boot provisioning for Singularity OS, in Go (replaces the
// 172-line shell script). Runs once as root at first boot: creates the user, seals
// the PIN via sintykey (the crypto path), sets identity/appearance, configures
// greetd, and provisions device-key fscrypt. No shell interpreter in a privileged
// crypto path -- every external tool is exec'd with an explicit argv (no /bin/sh -c,
// no word-splitting/glob/IFS surface). Idempotent via /var/lib/sinty/.oobe-done.
//
// Input: OOBE_* environment (username, hostname, ...) + the PIN on stdin.
package main

import (
	"bufio"
	"fmt"
	"context"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// cmdTimeout bounds every external tool: no provisioning step may hang forever. A step that
// blocks (e.g. an NSS/DNS lookup with a nameserver but no route) would otherwise wedge the
// whole OOBE. Well above any real useradd/sintykey/TPM time, so it only ever kills a hang.
const cmdTimeout = 45 * time.Second

const (
	markerDir  = "/var/lib/sinty"
	marker     = "/var/lib/sinty/.oobe-done"
	varHome    = "/var/home"
	avatarDir  = "/usr/share/singularity/avatars"
	greetdCfg  = "/etc/greetd/config.toml"
	logPath    = "/run/atom-firstboot.log"
	deviceMark = "/var/lib/sinty/device.pub"
)

var logw io.Writer = os.Stderr

func logf(format string, a ...any) { fmt.Fprintf(logw, "[firstboot] "+format+"\n", a...) }
func fail(format string, a ...any) {
	fmt.Fprintf(logw, "[firstboot] ERROR: "+format+"\n", a...)
	os.Exit(1)
}

// run execs name with args and an explicit argv (never a shell). Returns combined output.
// A per-command timeout kills any tool that hangs so provisioning can never wedge.
func run(name string, args ...string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), cmdTimeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, name, args...)
	out, err := cmd.CombinedOutput()
	if ctx.Err() == context.DeadlineExceeded {
		return string(out), fmt.Errorf("%s timed out after %s", name, cmdTimeout)
	}
	return string(out), err
}

// runStdin is run() with data on stdin (used to hand the PIN to sintykey, never argv).
func runStdin(stdin string, name string, args ...string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), cmdTimeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Stdin = strings.NewReader(stdin)
	out, err := cmd.CombinedOutput()
	if ctx.Err() == context.DeadlineExceeded {
		return string(out), fmt.Errorf("%s timed out after %s", name, cmdTimeout)
	}
	return string(out), err
}

func have(tool string) bool { _, err := exec.LookPath(tool); return err == nil }
func exists(p string) bool  { _, err := os.Stat(p); return err == nil }

func isSinty() bool {
	b, err := os.ReadFile("/etc/os-release")
	if err != nil {
		return false
	}
	for _, ln := range strings.Split(string(b), "\n") {
		if strings.HasPrefix(ln, "ID=sinty") || strings.HasPrefix(ln, `ID="sinty`) {
			return true
		}
	}
	return false
}

func main() {
	// Provisioning tools live in /usr/sbin (useradd, usermod) and /usr/bin (sintykey, id,
	// chown, cp, mkpasswd). The OOBE session that spawns us does not guarantee /usr/sbin on
	// PATH, so useradd was not found and provisioning aborted. Pin a deterministic PATH so
	// every tool resolves regardless of the caller's environment.
	os.Setenv("PATH", "/usr/sbin:/sbin:/usr/bin:/bin")

	var writers []io.Writer
	if f, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644); err == nil {
		writers = append(writers, f)
		defer f.Close()
	}
	// Mirror the log to the console so each step is visible on serial even when the OOBE UI
	// has frozen and there is no getty: the OOBE runs before any login shell, so /run logs are
	// otherwise unreachable on a wedged boot.
	if c, err := os.OpenFile("/dev/console", os.O_WRONLY, 0); err == nil {
		writers = append(writers, c)
		defer c.Close()
	}
	if len(writers) > 0 {
		logw = io.MultiWriter(writers...)
	}
	if os.Geteuid() != 0 {
		fail("must run as root")
	}
	if exists(marker) {
		logf("already provisioned, nothing to do")
		return
	}

	user := os.Getenv("OOBE_USERNAME")
	if user == "" {
		fail("OOBE_USERNAME is required")
	}
	hostname := envOr("OOBE_HOSTNAME", "sinty")
	fullname := os.Getenv("OOBE_FULLNAME")
	autologin := os.Getenv("OOBE_AUTOLOGIN") == "1"
	sinty := isSinty()

	pinBytes, _ := io.ReadAll(bufio.NewReader(os.Stdin))
	pin := strings.TrimRight(string(pinBytes), "\r\n")

	shell := "/bin/sh"
	if exists("/bin/bash") {
		shell = "/bin/bash"
	}
	homeDir := filepath.Join(varHome, user)

	// 1. user account
	if _, err := run("id", user); err != nil {
		logf("creating user %s (home %s)", user, homeDir)
		os.MkdirAll(varHome, 0o755)
		if sinty {
			if out, err := run("useradd", "--no-create-home", "--home-dir", homeDir,
				"--shell", shell, "--comment", fullname, user); err != nil {
				fail("useradd: %v: %s", err, out)
			}
			os.MkdirAll(homeDir, 0o700)
			run("chown", user, homeDir)
			os.Chmod(homeDir, 0o700)
		} else {
			if out, err := run("useradd", "--create-home", "--home-dir", homeDir,
				"--shell", shell, "--comment", fullname, user); err != nil {
				fail("useradd: %v: %s", err, out)
			}
		}
	}

	// 2. groups (best-effort; a missing group is not fatal)
	for _, g := range []string{"wheel", "sudo", "audio", "video", "input", "render", "seat", "netdev", "plugdev", "bluetooth"} {
		run("usermod", "-aG", g, user)
	}

	// 3. subordinate uid/gid ranges for rootless containers
	for _, f := range []string{"/etc/subuid", "/etc/subgid"} {
		ensureLine(f, user+":", fmt.Sprintf("%s:100000:65536\n", user))
	}
	logf("subordinate id ranges ensured for %s", user)

	// 4. credential: seal the PIN via sintykey (Sinty), else a password hash
	if pin != "" {
		if sinty && have("sintykey") {
			uidNum := strings.TrimSpace(mustRun("id", "-u", user))
			rec, err := runStdin(pin, "sintykey", "provision", "--user", user, "--uid", uidNum, "--home", homeDir)
			run("usermod", "-p", "*", user) // no Unix password; the PIN unlocks via pam_sinty
			if err == nil && strings.TrimSpace(rec) != "" {
				os.WriteFile("/run/sinty-recovery-code", []byte(strings.TrimSpace(rec)+"\n"), 0o600)
				logf("PIN provisioned via sintykey (recovery code staged)")
			} else {
				logf("sintykey provision failed; account has no Unix password")
			}
		} else {
			hash, err := run("mkpasswd", "-m", "sha512", pin)
			if err != nil {
				hash, _ = run("busybox", "mkpasswd", "-m", "sha512", pin)
			}
			if h := strings.TrimSpace(hash); h != "" {
				run("usermod", "-p", h, user)
				logf("password set")
			}
		}
	} else {
		logf("no password provided (account left without one)")
	}

	// 5. home skel (Sinty: home was created empty)
	if sinty && exists("/etc/skel") {
		run("cp", "-aT", "/etc/skel", homeDir)
		run("chown", "-R", user+":"+user, homeDir)
		logf("home skel populated")
	}

	// 6. avatar (AccountsService)
	setAvatar(user)

	// 7. identity: hostname, locale, keymap, theme
	os.WriteFile("/etc/hostname", []byte(hostname+"\n"), 0o644)
	logf("hostname set to %s", hostname)
	if loc := os.Getenv("OOBE_LOCALE"); loc != "" {
		os.WriteFile("/etc/locale.conf", []byte("LANG="+loc+"\n"), 0o644)
		logf("locale set to %s", loc)
	}
	if km := os.Getenv("OOBE_KEYMAP"); km != "" {
		os.WriteFile("/etc/vconsole.conf", []byte("KEYMAP="+km+"\nXKBLAYOUT="+km+"\n"), 0o644)
		logf("keymap set to %s", km)
	}
	switch os.Getenv("OOBE_THEME") {
	case "light", "dual", "dark":
		theme := os.Getenv("OOBE_THEME")
		d := filepath.Join(homeDir, ".config/sinty")
		os.MkdirAll(d, 0o755)
		os.WriteFile(filepath.Join(d, "theme-mode"), []byte(theme+"\n"), 0o644)
		run("chown", "-R", user, filepath.Join(homeDir, ".config"))
		logf("appearance set to %s", theme)
	}

	// 8. greetd (default session + optional autologin)
	configureGreetd(user, autologin)

	// 9. hide the baked template user from the greeter
	if user != "sinty" {
		if _, err := run("id", "sinty"); err == nil {
			run("usermod", "-s", "/sbin/nologin", "sinty")
			logf("hid baked template user sinty from the greeter (nologin)")
		}
	}

	// 10. device-key (DE) fscrypt for /var system dirs, once, on empty dirs
	if sinty && have("sintykey") && !exists(deviceMark) {
		for _, d := range []string{"/var/log", "/var/cache", "/var/spool"} {
			os.MkdirAll(d, 0o755)
			emptyDir(d)
		}
		if _, err := run("sintykey", "provision-device"); err == nil {
			logf("DE device-key fscrypt provisioned (/var/log,cache,spool encrypted, device-bound)")
		} else {
			logf("sintykey provision-device failed (DE not set)")
		}
	}

	// 11. done marker
	os.MkdirAll(markerDir, 0o755)
	os.WriteFile(marker, []byte(time.Now().UTC().Format("2006-01-02T15:04:05Z")+"\n"), 0o644)
	logf("first-boot provisioning complete")
}

func envOr(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func mustRun(name string, args ...string) string {
	out, err := run(name, args...)
	if err != nil {
		fail("%s: %v", name, err)
	}
	return out
}

// ensureLine appends line to file if no existing line starts with prefix.
func ensureLine(file, prefix, line string) {
	b, _ := os.ReadFile(file)
	for _, ln := range strings.Split(string(b), "\n") {
		if strings.HasPrefix(ln, prefix) {
			return
		}
	}
	f, err := os.OpenFile(file, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
	if err != nil {
		return
	}
	defer f.Close()
	f.WriteString(line)
}

func emptyDir(dir string) {
	entries, _ := os.ReadDir(dir)
	for _, e := range entries {
		os.RemoveAll(filepath.Join(dir, e.Name()))
	}
}

func setAvatar(user string) {
	var src string
	if c := os.Getenv("OOBE_AVATAR_CUSTOM"); c != "" && exists(c) {
		src = c
	} else if a := os.Getenv("OOBE_AVATAR"); a != "" {
		p := filepath.Join(avatarDir, a+".png")
		if exists(p) {
			src = p
		}
	}
	if src == "" {
		return
	}
	os.MkdirAll("/var/lib/AccountsService/icons", 0o755)
	os.MkdirAll("/var/lib/AccountsService/users", 0o755)
	iconDst := "/var/lib/AccountsService/icons/" + user
	run("cp", src, iconDst)
	os.Chmod(iconDst, 0o644)
	uf := "/var/lib/AccountsService/users/" + user
	if !exists(uf) {
		os.WriteFile(uf, []byte("[User]\nIcon=/var/lib/AccountsService/icons/"+user+"\n"), 0o644)
	} else if b, _ := os.ReadFile(uf); !strings.Contains(string(b), "\nIcon=") && !strings.HasPrefix(string(b), "Icon=") {
		f, _ := os.OpenFile(uf, os.O_WRONLY|os.O_APPEND, 0o644)
		if f != nil {
			f.WriteString("Icon=/var/lib/AccountsService/icons/" + user + "\n")
			f.Close()
		}
	}
	logf("avatar set")
}

// configureGreetd rewrites greetd's config: greeter as default_session, and the user
// as initial_session when autologin is on. Exported-ish shape kept for a unit test.
func configureGreetd(user string, autologin bool) {
	if !exists(greetdCfg) {
		logf("greetd config not found, skipping login setup")
		return
	}
	sessionCmd := greetdSessionCmd(greetdCfg)
	os.WriteFile(greetdCfg, []byte(greetdConfigText(sessionCmd, user, autologin)), 0o644)
	logf("greetd configured (autologin=%v, user=%s)", autologin, user)
}

// greetdSessionCmd extracts the first `command = "..."` value, defaulting to
// singularity-session.
func greetdSessionCmd(path string) string {
	b, _ := os.ReadFile(path)
	for _, ln := range strings.Split(string(b), "\n") {
		t := strings.TrimSpace(ln)
		if strings.HasPrefix(t, "command") {
			if i := strings.Index(t, `"`); i >= 0 {
				if j := strings.Index(t[i+1:], `"`); j >= 0 {
					return t[i+1 : i+1+j]
				}
			}
		}
	}
	return "singularity-session"
}

func greetdConfigText(sessionCmd, user string, autologin bool) string {
	var b strings.Builder
	fmt.Fprintf(&b, "[terminal]\nvt = 1\n\n[default_session]\ncommand = %q\nuser = \"greeter\"\n", sessionCmd)
	if autologin {
		fmt.Fprintf(&b, "\n[initial_session]\ncommand = %q\nuser = %q\n", sessionCmd, user)
	}
	return b.String()
}
