// Command atom-install provisions a target disk from the live source (ESP + verified
// erofs root + hash tree + a fresh f2fs /var). This file holds the pure, testable core:
// classifying the live source partitions by on-disk magic, computing partition sizes,
// and generating the GPT layout and greetd config. The disk-mutating steps (sfdisk, dd,
// mkfs, efibootmgr) are thin argv exec wrappers in install.go -- no /bin/sh anywhere.
package main

import "fmt"

// PartKind is what a candidate source partition turned out to be.
type PartKind int

const (
	KindUnknown PartKind = iota
	KindEROFS            // the read-only root image
	KindHash             // the dm-verity hash tree
	KindESP              // the FAT ESP carrying the loader
)

// erofsMagic is the 4 bytes at offset 1024 of an erofs superblock.
var erofsMagic = []byte{0xe2, 0xe1, 0xf5, 0xe0}

// classify decides what a partition is from a header read at offset 0 (>= 1028 bytes)
// plus whether a vfat mount of it exposes the loader. The order matters: hash first
// (its "verity" magic is unambiguous), then erofs by superblock magic, then ESP.
func classify(header []byte, espHasLoader bool) PartKind {
	if len(header) >= 6 && string(header[0:6]) == "verity" {
		return KindHash
	}
	if len(header) >= 1028 && bytesEqual(header[1024:1028], erofsMagic) {
		return KindEROFS
	}
	if espHasLoader {
		return KindESP
	}
	return KindUnknown
}

func bytesEqual(a, b []byte) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

// mibOf rounds a byte count up to whole MiB (partitions must not be undersized).
func mibOf(sizeBytes int64) int64 {
	return (sizeBytes + (1 << 20) - 1) / (1 << 20)
}

// partitionTable is the sfdisk GPT script: ESP, root, hash (all fixed-size) and a
// var partition that takes the rest of the disk.
func partitionTable(espMB, erofsMB, hashMB int64) string {
	return fmt.Sprintf(`label: gpt
size=%dMiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name=ESP, bootable
size=%dMiB, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=sing-root
size=%dMiB, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=sing-hash
type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=atom-var
`, espMB, erofsMB, hashMB)
}

// greetdConfig is the first-boot greetd config: OOBE as root on the very first boot,
// the greeter session afterwards.
func greetdConfig() string {
	return `[terminal]
vt = 1

[default_session]
command = "/usr/bin/labwc -s /usr/bin/singularity-greeter"
user = "greeter"

[initial_session]
command = "/usr/bin/atom-oobe-session"
user = "root"
`
}
