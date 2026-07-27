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
	pt := partitionTable(256)
	for _, want := range []string{"label: gpt", "256MiB", "name=ESP, bootable", "name=atom-data"} {
		if !contains(pt, want) {
			t.Errorf("partition table missing %q", want)
		}
	}
	// One data partition taking the rest of the disk: no reserved second slot, and no
	// separate system partition to size.
	if contains(pt, "atom-system") || contains(pt, "atom-var") {
		t.Error("partition table still carries the old split layout")
	}
	// The installed config must keep the image's own default_session (how the greeter is
	// really started) and only swap the initial_session over to the OOBE.
	live := `[terminal]
vt = 1

[default_session]
command = "/usr/bin/singularity-greeter-client"
user = "greeter"

[initial_session]
command = "/usr/bin/atom-install-session"
user = "root"
`
	g := installedGreetdConfig(live)
	if !contains(g, "atom-oobe-session") {
		t.Error("installed greetd config does not run the OOBE on the first boot")
	}
	if contains(g, "atom-install-session") {
		t.Error("installed greetd config still starts the live installer")
	}
	if !contains(g, "singularity-greeter-client") {
		t.Error("installed greetd config dropped the image's own greeter session")
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
