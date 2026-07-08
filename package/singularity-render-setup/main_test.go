package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func fakeCard(t *testing.T, root, card, driver string) {
	d := filepath.Join(root, card, "device")
	if err := os.MkdirAll(d, 0o755); err != nil {
		t.Fatal(err)
	}
	body := "OF_NAME=gpu\n"
	if driver != "" {
		body = "DRIVER=" + driver + "\nOF_NAME=gpu\n"
	}
	if err := os.WriteFile(filepath.Join(d, "uevent"), []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestHardwareDetection(t *testing.T) {
	root := t.TempDir()
	fakeCard(t, root, "card0", "i915") // real GPU
	if !hasHardwareGPU(filepath.Join(root, "card[0-9]*")) {
		t.Fatal("i915 should be detected as hardware")
	}
}

func TestSoftwareFallback(t *testing.T) {
	root := t.TempDir()
	fakeCard(t, root, "card0", "virtio_gpu") // VM, not in the hw list
	fakeCard(t, root, "card1", "")           // no driver
	if hasHardwareGPU(filepath.Join(root, "card[0-9]*")) {
		t.Fatal("virtio_gpu must NOT count as hardware")
	}
	// run() must append the software env when no hw GPU
	env := filepath.Join(root, "environment")
	if rc := run(filepath.Join(root, "card[0-9]*"), env); rc != 0 {
		t.Fatalf("run rc=%d", rc)
	}
	b, _ := os.ReadFile(env)
	if !strings.Contains(string(b), "kms_swrast") {
		t.Fatal("software env not written")
	}
}

func TestHardwareSkipsEnv(t *testing.T) {
	root := t.TempDir()
	fakeCard(t, root, "card0", "amdgpu")
	env := filepath.Join(root, "environment")
	run(filepath.Join(root, "card[0-9]*"), env)
	if _, err := os.Stat(env); err == nil {
		t.Fatal("hardware GPU must not write the software env")
	}
}
