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
