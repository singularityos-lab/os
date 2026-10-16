package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestGreetdConfigText(t *testing.T) {
	// no autologin: default_session only, greeter user
	got := greetdConfigText("singularity-session", "testuser", false)
	if !strings.Contains(got, `command = "singularity-session"`) ||
		!strings.Contains(got, `user = "greeter"`) {
		t.Fatalf("default_session malformed:\n%s", got)
	}
	if strings.Contains(got, "initial_session") {
		t.Fatalf("no-autologin must NOT emit initial_session:\n%s", got)
	}
	// autologin: initial_session with the real user
	got = greetdConfigText("singularity-session", "testuser", true)
	if !strings.Contains(got, "[initial_session]") || !strings.Contains(got, `user = "testuser"`) {
		t.Fatalf("autologin must emit initial_session for the user:\n%s", got)
	}
}

func TestGreetdSessionCmd(t *testing.T) {
	dir := t.TempDir()
	p := filepath.Join(dir, "config.toml")
	os.WriteFile(p, []byte("[default_session]\ncommand = \"custom-session\"\nuser = \"greeter\"\n"), 0o644)
	if v := greetdSessionCmd(p); v != "custom-session" {
		t.Fatalf("got %q want custom-session", v)
	}
	// missing file -> default
	if v := greetdSessionCmd(filepath.Join(dir, "nope")); v != "singularity-session" {
		t.Fatalf("missing config should default, got %q", v)
	}
}

func TestRunStdinDoesNotWaitForOrphanedChildren(t *testing.T) {
	start := time.Now()
	runStdin("secret", "sh", "-c", "sleep 120 & cat >/dev/null")
	if d := time.Since(start); d > waitDelay+10*time.Second {
		t.Fatalf("runStdin waited %s for a child that kept the output pipe open", d)
	}
}

func TestRunStdinKeepsDiagnosticsOutOfStdout(t *testing.T) {
	out, diag, err := runStdin("pin", "sh", "-c", "cat >/dev/null; echo note >&2; echo CODE")
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(out) != "CODE" {
		t.Fatalf("stdout mixed with stderr: %q", out)
	}
	if strings.TrimSpace(diag) != "note" {
		t.Fatalf("stderr lost: %q", diag)
	}
}
