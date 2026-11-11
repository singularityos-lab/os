package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type releaseDir struct {
	dir, arch, version string
	recovery           int
}

func readRelease(dir string) (releaseDir, error) {
	b, err := os.ReadFile(filepath.Join(dir, "manifest.json"))
	if err != nil {
		return releaseDir{}, fmt.Errorf("release: %w", err)
	}
	var m struct {
		Version  string `json:"version"`
		Arch     string `json:"arch"`
		Recovery int    `json:"recovery_version"`
	}
	if err := json.Unmarshal(b, &m); err != nil {
		return releaseDir{}, fmt.Errorf("release manifest: %w", err)
	}
	if m.Version == "" {
		return releaseDir{}, fmt.Errorf("release manifest: missing version")
	}
	if m.Arch == "" {
		m.Arch = "x86_64"
	}
	r := releaseDir{dir: dir, arch: m.Arch, version: m.Version, recovery: m.Recovery}
	for _, f := range r.espFiles() {
		if !fileExists(f[0]) {
			return releaseDir{}, fmt.Errorf("release: missing %s", filepath.Base(f[0]))
		}
	}
	for _, f := range []string{r.erofs(), r.hash()} {
		if !fileExists(f) {
			return releaseDir{}, fmt.Errorf("release: missing %s", filepath.Base(f))
		}
	}
	return r, nil
}

func (r releaseDir) espMB() int64 {
	if r.arch == "aarch64" {
		return 512
	}
	return 256
}

func (r releaseDir) erofs() string { return filepath.Join(r.dir, "rootfs.erofs") }
func (r releaseDir) hash() string  { return filepath.Join(r.dir, "rootfs.hash") }

func loaderFileName(arch string) string {
	if arch == "aarch64" {
		return "BOOTAA64.EFI"
	}
	return "BOOTX64.EFI"
}

func (r releaseDir) espFiles() [][2]string {
	in := func(n string) string { return filepath.Join(r.dir, n) }
	files := [][2]string{
		{in("loader.efi"), "EFI/BOOT/" + loaderFileName(r.arch)},
		{in("kernelcache.efi"), "EFI/atom/kernelcache-active.efi"},
		{in("kernelcache.efi.sig"), "EFI/atom/kernelcache-active.efi.sig"},
		{in("signing-cert.json"), "EFI/atom/signing-cert.json"},
		{in("signing-cert.json.sig"), "EFI/atom/signing-cert.json.sig"},
	}
	if fileExists(in("kernelcache-recovery.efi")) && fileExists(in("kernelcache-recovery.efi.sig")) {
		files = append(files,
			[2]string{in("kernelcache-recovery.efi"), "EFI/atom/kernelcache-recovery.efi"},
			[2]string{in("kernelcache-recovery.efi.sig"), "EFI/atom/kernelcache-recovery.efi.sig"})
	}
	entries, _ := os.ReadDir(r.dir)
	for _, e := range entries {
		family, ok := strings.CutPrefix(e.Name(), "kernelcache.")
		if !ok {
			continue
		}
		family, ok = strings.CutSuffix(family, ".efi")
		if !ok || family == "" || strings.Contains(family, ".") || !fileExists(in(e.Name()+".sig")) {
			continue
		}
		files = append(files,
			[2]string{in(e.Name()), "EFI/atom/kernelcache-active." + family + ".efi"},
			[2]string{in(e.Name() + ".sig"), "EFI/atom/kernelcache-active." + family + ".efi.sig"})
	}
	return files
}

func (r releaseDir) sources() []string {
	out := []string{r.erofs(), r.hash()}
	for _, f := range r.espFiles() {
		out = append(out, f[0])
	}
	return out
}

func deploymentWAL(version string, recovery int) []byte {
	rv := ""
	if recovery > 0 {
		rv = fmt.Sprint(recovery)
	}
	return []byte(fmt.Sprintf(`{
  "rootfs": { "current": %q, "pending": "", "rollback": "", "boot_attempts": 0, "max_attempts": 3, "last_known_good": %q },
  "recovery": { "version": %q, "path": "", "last_updated": "" },
  "kernelcache": { "state": "stable", "stable_boots": 0, "stable_threshold": 3, "format": "uki" },
  "security": { "level": 2, "dm_verity": true, "secure_boot": false }
}
`, version, version, rv))
}

func populateESP(root string, r releaseDir) error {
	for _, d := range []string{"EFI/BOOT", "EFI/atom"} {
		if err := os.MkdirAll(filepath.Join(root, d), 0o755); err != nil {
			return err
		}
	}
	for _, f := range r.espFiles() {
		if err := copyData(f[0], filepath.Join(root, f[1])); err != nil {
			return err
		}
	}
	if err := os.WriteFile(filepath.Join(root, "EFI/atom/boot-state"), []byte("target=active\ntrial=0\nattempts=0\n"), 0o644); err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(root, "EFI/atom/deployment.json"), deploymentWAL(r.version, r.recovery), 0o644)
}

func buildESP(part string, r releaseDir) (err error) {
	if err := run("mkfs.fat", "-F", "32", "-n", "SINGEFI", part); err != nil {
		return err
	}
	mnt, err := mountTemp("atom-esp-release", "-t", "vfat", part)
	if err != nil {
		return err
	}
	defer func() {
		if rerr := release(mnt); err == nil {
			err = rerr
		}
	}()
	if err := populateESP(mnt, r); err != nil {
		return err
	}
	return run("sync", "-f", mnt)
}
