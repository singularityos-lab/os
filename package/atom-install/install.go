package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

// run executes a command with an explicit argv (never a shell) and returns a wrapped
// error including stderr. This is the whole point of porting off /bin/sh: no word
// splitting, no injection, every disk operation is an exact argv.
func run(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%s %s: %w: %s", name, strings.Join(args, " "), err, strings.TrimSpace(string(out)))
	}
	return nil
}

// deviceSizeBytes reads a block device/partition size from sysfs (512-byte sectors).
func deviceSizeBytes(dev string) (int64, error) {
	b, err := os.ReadFile(filepath.Join("/sys/class/block", filepath.Base(dev), "size"))
	if err != nil {
		return 0, err
	}
	sectors, err := strconv.ParseInt(strings.TrimSpace(string(b)), 10, 64)
	if err != nil {
		return 0, err
	}
	return sectors * 512, nil
}

// readHeader reads n bytes from the start of a device.
func readHeader(dev string, n int) []byte {
	f, err := os.Open(dev)
	if err != nil {
		return nil
	}
	defer f.Close()
	buf := make([]byte, n)
	m, _ := f.Read(buf)
	return buf[:m]
}

// espHasLoader mounts dev read-only and reports whether it carries the loader.
func espHasLoader(dev string) bool {
	mnt, err := os.MkdirTemp("", "espprobe")
	if err != nil {
		return false
	}
	defer os.Remove(mnt)
	if run("mount", "-t", "vfat", "-o", "ro", dev, mnt) != nil {
		return false
	}
	defer run("umount", mnt)
	_, err = os.Stat(filepath.Join(mnt, "EFI", "BOOT", "BOOTX64.EFI"))
	return err == nil
}

// candidatePartitions lists block partitions, excluding the target disk.
func candidatePartitions(target string) []string {
	var out []string
	globs := []string{"/dev/vd*[0-9]", "/dev/sd*[0-9]", "/dev/nvme*p[0-9]*", "/dev/mmcblk*p[0-9]*"}
	for _, g := range globs {
		m, _ := filepath.Glob(g)
		for _, d := range m {
			if strings.HasPrefix(d, target) {
				continue // never treat a slice of the target as a source
			}
			out = append(out, d)
		}
	}
	return out
}

// detectSources finds the live ESP, erofs root and verity hash partitions.
func detectSources(target string) (esp, erofs, hash string, err error) {
	for _, d := range candidatePartitions(target) {
		h := readHeader(d, 1028)
		switch classify(h, false) {
		case KindHash:
			if hash == "" {
				hash = d
			}
			continue
		case KindEROFS:
			if erofs == "" {
				erofs = d
			}
			continue
		}
		if esp == "" && espHasLoader(d) {
			esp = d
		}
	}
	if esp == "" || erofs == "" || hash == "" {
		return "", "", "", fmt.Errorf("live source not found (esp=%q erofs=%q hash=%q)", esp, erofs, hash)
	}
	return esp, erofs, hash, nil
}

// partName returns the Nth partition node name for a disk (/dev/sda3, /dev/nvme0n1p3).
func partName(disk string, n int) string {
	last := disk[len(disk)-1]
	if last >= '0' && last <= '9' {
		return fmt.Sprintf("%sp%d", disk, n)
	}
	return fmt.Sprintf("%s%d", disk, n)
}

func mibOfDev(dev string) (int64, error) {
	b, err := deviceSizeBytes(dev)
	if err != nil {
		return 0, err
	}
	return mibOf(b), nil
}

func main() {
	if os.Geteuid() != 0 {
		fmt.Fprintln(os.Stderr, "atom-install: must run as root")
		os.Exit(1)
	}
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: atom-install /dev/DISK")
		os.Exit(1)
	}
	dev := os.Args[1]
	if fi, err := os.Stat(dev); err != nil || fi.Mode()&os.ModeDevice == 0 {
		fmt.Fprintf(os.Stderr, "atom-install: %s is not a block device\n", dev)
		os.Exit(1)
	}

	esp, erofs, hash, err := detectSources(dev)
	die(err)
	espMB, err := mibOfDev(esp)
	die(err)
	erofsMB, err := mibOfDev(erofs)
	die(err)
	hashMB, err := mibOfDev(hash)
	die(err)

	// partition
	sf := exec.Command("sfdisk", dev)
	sf.Stdin = strings.NewReader(partitionTable(espMB, erofsMB, hashMB))
	if out, e := sf.CombinedOutput(); e != nil {
		die(fmt.Errorf("sfdisk: %w: %s", e, out))
	}
	_ = run("partprobe", dev)

	// write ESP, verified root and hash tree, then a fresh /var
	die(run("dd", "if="+esp, "of="+partName(dev, 1), "bs=4M", "conv=fsync"))
	die(run("dd", "if="+erofs, "of="+partName(dev, 2), "bs=4M", "conv=fsync"))
	die(run("dd", "if="+hash, "of="+partName(dev, 3), "bs=4M", "conv=fsync"))
	die(setupVar(partName(dev, 4)))
	setUEFIEntry(dev) // best-effort

	fmt.Printf("atom-install: %s provisioned\n", dev)
}

// setupVar makes the encrypted f2fs /var and seeds the first-boot greetd config.
func setupVar(part string) error {
	if err := run("mkfs.f2fs", "-f", "-l", "atom-var", "-O", "encrypt,extra_attr", part); err != nil {
		return err
	}
	mnt, err := os.MkdirTemp("", "atomvar")
	if err != nil {
		return err
	}
	defer os.Remove(mnt)
	if err := run("mount", "-t", "f2fs", part, mnt); err != nil {
		return err
	}
	defer run("umount", mnt)
	for _, d := range []string{"home", "etc-upper", "etc-work", "lib", "log", "cache", "spool", "tmp", "run", "etc-upper/greetd"} {
		if err := os.MkdirAll(filepath.Join(mnt, d), 0o755); err != nil {
			return err
		}
	}
	os.Chmod(filepath.Join(mnt, "tmp"), 0o1777)
	os.WriteFile(filepath.Join(mnt, ".atom-var"), nil, 0o644)
	return os.WriteFile(filepath.Join(mnt, "etc-upper", "greetd", "config.toml"), []byte(greetdConfig()), 0o644)
}

// setUEFIEntry points the firmware at the internal disk so a leftover install USB does
// not boot the live image. Best-effort: efivars may be read-only.
func setUEFIEntry(disk string) {
	if _, err := os.Stat("/sys/firmware/efi"); err != nil {
		return
	}
	_ = run("efibootmgr", "-c", "-d", disk, "-p", "1", "-L", "Singularity", "-l", `\EFI\BOOT\BOOTX64.EFI`)
}

func die(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, "atom-install:", err)
		os.Exit(1)
	}
}
