package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func fakeRelease(t *testing.T, arch string) string {
	t.Helper()
	dir := t.TempDir()
	m := `{"version":"v9","recovery_version":4` + map[bool]string{true: `,"arch":"` + arch + `"`, false: ``}[arch != ""] + `}`
	files := map[string]string{"manifest.json": m}
	for _, n := range []string{"rootfs.erofs", "rootfs.hash", "kernelcache.efi", "kernelcache.efi.sig", "loader.efi",
		"signing-cert.json", "signing-cert.json.sig", "kernelcache-recovery.efi", "kernelcache-recovery.efi.sig"} {
		files[n] = arch + " " + n
	}
	for n, b := range files {
		if err := os.WriteFile(filepath.Join(dir, n), []byte(b), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return dir
}

func TestParseArgs(t *testing.T) {
	for _, c := range []struct {
		args      []string
		key       bool
		from, dev string
		bad       bool
	}{
		{args: []string{"/dev/sda"}, dev: "/dev/sda"},
		{args: []string{"--key", "/dev/sda"}, key: true, dev: "/dev/sda"},
		{args: []string{"--key", "--from", "/r", "/dev/sda"}, key: true, from: "/r", dev: "/dev/sda"},
		{args: []string{"--from", "/r", "--key", "/dev/sda"}, key: true, from: "/r", dev: "/dev/sda"},
		{args: []string{"--from", "/r", "/dev/sda"}, bad: true},
		{args: []string{"--key", "--from", "/dev/sda"}, bad: true},
		{args: []string{"--bogus", "/dev/sda"}, bad: true},
		{args: nil, bad: true},
	} {
		key, from, dev, err := parseArgs(c.args)
		if c.bad {
			if err == nil {
				t.Errorf("%v accepted", c.args)
			}
			continue
		}
		if err != nil || key != c.key || from != c.from || dev != c.dev {
			t.Errorf("%v: %v %q %q %v", c.args, key, from, dev, err)
		}
	}
}

func TestPopulateESPFromAnARMRelease(t *testing.T) {
	r, err := readRelease(fakeRelease(t, "aarch64"))
	if err != nil {
		t.Fatal(err)
	}
	esp := t.TempDir()
	if err := populateESP(esp, r); err != nil {
		t.Fatal(err)
	}
	for path, want := range map[string]string{
		"EFI/BOOT/BOOTAA64.EFI":                 "aarch64 loader.efi",
		"EFI/atom/kernelcache-active.efi":       "aarch64 kernelcache.efi",
		"EFI/atom/kernelcache-active.efi.sig":   "aarch64 kernelcache.efi.sig",
		"EFI/atom/kernelcache-recovery.efi":     "aarch64 kernelcache-recovery.efi",
		"EFI/atom/kernelcache-recovery.efi.sig": "aarch64 kernelcache-recovery.efi.sig",
		"EFI/atom/signing-cert.json":            "aarch64 signing-cert.json",
		"EFI/atom/signing-cert.json.sig":        "aarch64 signing-cert.json.sig",
		"EFI/atom/boot-state":                   "target=active\ntrial=0\nattempts=0\n",
	} {
		got, err := os.ReadFile(filepath.Join(esp, path))
		if err != nil || string(got) != want {
			t.Errorf("%s: %q %v", path, got, err)
		}
	}
	if _, err := os.Stat(filepath.Join(esp, "EFI/BOOT/BOOTX64.EFI")); !os.IsNotExist(err) {
		t.Errorf("x86 loader path written for an ARM release: %v", err)
	}
	var wal struct {
		Recovery struct {
			Version string `json:"version"`
		} `json:"recovery"`
		RootFS struct {
			Current       string `json:"current"`
			LastKnownGood string `json:"last_known_good"`
		} `json:"rootfs"`
	}
	b, _ := os.ReadFile(filepath.Join(esp, "EFI/atom/deployment.json"))
	if err := json.Unmarshal(b, &wal); err != nil || wal.RootFS.Current != "v9" || wal.RootFS.LastKnownGood != "v9" || wal.Recovery.Version != "4" {
		t.Errorf("deployment.json %s: %v", b, err)
	}
}

func TestReleaseWithoutArchIsX86(t *testing.T) {
	r, err := readRelease(fakeRelease(t, ""))
	if err != nil || r.arch != "x86_64" || loaderFileName(r.arch) != "BOOTX64.EFI" {
		t.Fatalf("%+v %v", r, err)
	}
}

func TestReleaseMissingLoaderIsRefused(t *testing.T) {
	dir := fakeRelease(t, "aarch64")
	os.Remove(filepath.Join(dir, "loader.efi"))
	if _, err := readRelease(dir); err == nil || !strings.Contains(err.Error(), "loader.efi") {
		t.Fatalf("release without loader accepted: %v", err)
	}
}

func TestWriteDeploymentKeepsABackup(t *testing.T) {
	dir := t.TempDir()
	if err := copyDeployment("", dir, deploymentWAL("v9", 0)); err != nil {
		t.Fatal(err)
	}
	a, _ := os.ReadFile(filepath.Join(dir, "deployment.json"))
	b, _ := os.ReadFile(filepath.Join(dir, "deployment.json.bak"))
	if len(a) == 0 || string(a) != string(b) {
		t.Fatalf("%q %q", a, b)
	}
}

func TestCopyAnchor(t *testing.T) {
	slots := t.TempDir()
	os.WriteFile(filepath.Join(slots, "deployment.json"), []byte(`{"rootfs":{"current":"v7"}}`), 0o644)
	src := t.TempDir()
	os.MkdirAll(filepath.Join(src, "v7"), 0o755)
	for _, f := range anchorFiles[:3] {
		os.WriteFile(filepath.Join(src, "v7", f), []byte(f), 0o644)
	}
	if err := copyAnchor(slots, src); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(slots, "release")); !os.IsNotExist(err) {
		t.Fatal("partial anchor copied")
	}
	os.WriteFile(filepath.Join(src, "v7", anchorFiles[3]), []byte("sig"), 0o644)
	if err := copyAnchor(slots, src); err != nil {
		t.Fatal(err)
	}
	for _, f := range anchorFiles {
		if _, err := os.Stat(filepath.Join(slots, "release", "v7", f)); err != nil {
			t.Fatal(err)
		}
	}
	rel := t.TempDir()
	for _, f := range anchorFiles {
		os.WriteFile(filepath.Join(rel, f), []byte("rel "+f), 0o644)
	}
	if err := copyAnchor(slots, rel); err != nil {
		t.Fatal(err)
	}
	if b, _ := os.ReadFile(filepath.Join(slots, "release", "v7", "manifest.json")); string(b) != "rel manifest.json" {
		t.Fatalf("release dir not used: %q", b)
	}
}
