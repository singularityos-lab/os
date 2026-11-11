package main

import (
	"bytes"
	"os"
	"path/filepath"
	"testing"
)

func TestCopyDataCopiesAndCounts(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "src")
	dst := filepath.Join(dir, "dst")
	data := bytes.Repeat([]byte("sinty"), 3<<20)
	if err := os.WriteFile(src, data, 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(dst, bytes.Repeat([]byte("x"), len(data)+100), 0o644); err != nil {
		t.Fatal(err)
	}
	copied = progress{total: int64(len(data)), last: -1}
	if err := copyData(src, dst); err != nil {
		t.Fatal(err)
	}
	got, err := os.ReadFile(dst)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(got, data) {
		t.Fatalf("copy differs: %d bytes, want %d", len(got), len(data))
	}
	if copied.last != 100 || copied.done != int64(len(data)) {
		t.Fatalf("progress %d%% after %d bytes", copied.last, copied.done)
	}
}

func TestPromoteKeepsAnAlreadyActiveKernelcache(t *testing.T) {
	dir := t.TempDir()
	pairs := [][2]string{
		{filepath.Join(dir, "kernelcache-install.efi"), filepath.Join(dir, "kernelcache-active.efi")},
		{filepath.Join(dir, "kernelcache-install.efi.sig"), filepath.Join(dir, "kernelcache-active.efi.sig")},
	}
	for _, p := range pairs {
		os.WriteFile(p[1], []byte("active"), 0o644)
	}
	if err := promoteKernelcache(pairs); err != nil {
		t.Fatalf("installed system as source: %v", err)
	}
	for _, p := range pairs {
		os.WriteFile(p[0], []byte("install"), 0o644)
	}
	if err := promoteKernelcache(pairs); err != nil {
		t.Fatal(err)
	}
	if b, _ := os.ReadFile(pairs[0][1]); string(b) != "install" {
		t.Fatalf("install kernelcache not promoted: %q", b)
	}
	os.Remove(pairs[1][1])
	if err := promoteKernelcache(pairs); err == nil {
		t.Fatal("missing signature accepted")
	}
}

func TestFamilyKernelcachesArePromoted(t *testing.T) {
	dir := t.TempDir()
	for _, n := range []string{"kernelcache-install.efi", "kernelcache-install.l4t.efi", "kernelcache-install.l4t.efi.sig", "kernelcache-active.l4t.efi", "kernelcache-install.efi.sig", "kernelcache-recovery.efi"} {
		os.WriteFile(filepath.Join(dir, n), []byte(n), 0o644)
	}
	pairs, err := familyPairs(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(pairs) != 2 {
		t.Fatalf("pairs %v", pairs)
	}
	if err := promoteKernelcache(pairs); err != nil {
		t.Fatal(err)
	}
	if b, _ := os.ReadFile(filepath.Join(dir, "kernelcache-active.l4t.efi")); string(b) != "kernelcache-install.l4t.efi" {
		t.Fatalf("family kernelcache not promoted: %q", b)
	}
	if b, _ := os.ReadFile(filepath.Join(dir, "kernelcache-active.l4t.efi.sig")); string(b) != "kernelcache-install.l4t.efi.sig" {
		t.Fatalf("family signature not promoted: %q", b)
	}
	os.WriteFile(filepath.Join(dir, "kernelcache-install.rk.efi"), []byte("rk"), 0o644)
	pairs, _ = familyPairs(dir)
	if err := promoteKernelcache(pairs); err == nil {
		t.Fatal("family kernelcache without a signature accepted")
	}
}

func TestForgetSourceMachineDropsPinState(t *testing.T) {
	state := t.TempDir()
	os.MkdirAll(filepath.Join(state, "pin"), 0o755)
	os.WriteFile(filepath.Join(state, "pin", "1001.priv"), []byte("x"), 0o600)
	os.WriteFile(filepath.Join(state, "SINTYRESCUE.txt"), []byte("x"), 0o644)
	os.WriteFile(filepath.Join(state, "install-id"), []byte("id\n"), 0o644)
	if err := forgetSourceMachine(state); err != nil {
		t.Fatal(err)
	}
	if fileExists(filepath.Join(state, "pin")) || fileExists(filepath.Join(state, "SINTYRESCUE.txt")) {
		t.Fatal("source machine state copied to the new disk")
	}
	if !fileExists(filepath.Join(state, "install-id")) {
		t.Fatal("install id removed")
	}
	if err := forgetSourceMachine(state); err != nil {
		t.Fatalf("second run: %v", err)
	}
}
