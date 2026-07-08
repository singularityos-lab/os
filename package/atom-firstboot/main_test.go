package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
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
