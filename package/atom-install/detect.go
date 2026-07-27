// Command atom-install provisions a target disk from the live source (ESP + verified
// erofs root + hash tree + a fresh f2fs /var). This file holds the pure, testable core:
// classifying the live source partitions by on-disk magic, computing partition sizes,
// generating the GPT layout and deriving the installed greetd config from the live one.
// The disk-mutating steps (sfdisk, dd,
// mkfs, efibootmgr) are thin argv exec wrappers in install.go -- no /bin/sh anywhere.
package main

import (
	"fmt"
	"strings"
)

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

// partitionTable is the sfdisk GPT script: an ESP and ONE data partition taking the
// rest of the disk. Atom Loops needs no A/B layout and no separate system partition:
// the root image is a file on this partition, next to the user data, so a staged
// update simply uses free space instead of a reserved second slot.
func partitionTable(espMB int64) string {
	return fmt.Sprintf(`label: gpt
size=%dMiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name=ESP, bootable
type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=atom-data
`, espMB)
}

// liveGreetdConfig is the running image's greetd config, which the installed copy is
// derived from.
const liveGreetdConfig = "/etc/greetd/config.toml"

// installedGreetdConfig turns the live config into the installed one. Only the
// initial_session command changes: on the live medium it starts the installer, on a
// fresh disk the very first boot must run the OOBE instead. Everything else is carried
// over verbatim -- above all the default_session command, which is how the greeter is
// actually started and which has changed before (nested labwc -> client of the
// persistent compositor); a config written from scratch here would silently pin the old
// way and leave the installed system with a black screen at login.
func installedGreetdConfig(live string) string {
	var out []string
	inInitial := false
	for _, line := range strings.Split(live, "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "[") {
			inInitial = trimmed == "[initial_session]"
		}
		if inInitial && strings.HasPrefix(trimmed, "command") {
			out = append(out, `command = "/usr/bin/atom-oobe-session"`)
			continue
		}
		out = append(out, line)
	}
	return strings.Join(out, "\n")
}
