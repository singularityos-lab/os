package main

import "testing"

func TestClassify(t *testing.T) {
	hash := append([]byte("verity"), make([]byte, 2000)...)
	if classify(hash, false) != KindHash {
		t.Error("verity header must classify as hash")
	}
	erofs := make([]byte, 2000)
	copy(erofs[1024:], erofsMagic)
	if classify(erofs, false) != KindEROFS {
		t.Error("erofs superblock magic must classify as erofs")
	}
	blank := make([]byte, 2000)
	if classify(blank, true) != KindESP {
		t.Error("vfat with the loader must classify as ESP")
	}
	if classify(blank, false) != KindUnknown {
		t.Error("no magic and no loader must be unknown")
	}
}

func TestMibOf(t *testing.T) {
	if mibOf(1<<20) != 1 {
		t.Error("exactly 1MiB should be 1")
	}
	if mibOf(1<<20+1) != 2 {
		t.Error("1MiB+1 must round up to 2")
	}
	if mibOf(0) != 0 {
		t.Error("0 bytes = 0 MiB")
	}
}

func TestTemplates(t *testing.T) {
	pt := partitionTable(256, 900, 16)
	for _, want := range []string{"label: gpt", "256MiB", "name=ESP, bootable", "name=atom-var"} {
		if !contains(pt, want) {
			t.Errorf("partition table missing %q", want)
		}
	}
	g := greetdConfig()
	if !contains(g, "atom-oobe-session") || !contains(g, `user = "greeter"`) {
		t.Error("greetd config missing OOBE/greeter")
	}
}

func contains(s, sub string) bool {
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return true
		}
	}
	return false
}
