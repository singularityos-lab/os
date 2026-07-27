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
	// Two shapes of live medium install: the .img, whose root already IS a slot file on
	// the mounted system partition, and the .iso, which still appends the root image and
	// its hash tree as raw partitions. Prefer the mounted files -- booted from a .img
	// there is no raw erofs partition to find, so probing alone would fail the install.
	const activeErofs = "/boot/rootfs/rootfs-active.erofs"
	const activeHash = "/boot/rootfs/rootfs-active.hash"
	if fileExists(activeErofs) && fileExists(activeHash) {
		erofs, hash = activeErofs, activeHash
		// The initramfs already mounted the ESP, so probing it by mounting it again
		// read-only fails ("would change RO state"). Take the device from the mount
		// table instead, or the install aborts having found everything but the ESP.
		esp = mountedDevice("/boot/efi")
	}
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
	erofsMB, err := sourceMB(erofs)
	die(err)
	hashMB, err := sourceMB(hash)
	die(err)

	// partition
	sf := exec.Command("sfdisk", dev)
	sf.Stdin = strings.NewReader(partitionTable(espMB, systemMB(erofsMB, hashMB)))
	if out, e := sf.CombinedOutput(); e != nil {
		die(fmt.Errorf("sfdisk: %w: %s", e, out))
	}
	_ = run("partprobe", dev)

	die(run("dd", "if="+esp, "of="+partName(dev, 1), "bs=4M", "conv=fsync"))
	die(setupSystem(partName(dev, 2), erofs, hash, esp))
	die(setupVar(partName(dev, 3)))
	setUEFIEntry(dev) // best-effort

	fmt.Printf("atom-install: %s provisioned\n", dev)
}

// setupSystem builds the partition that becomes /boot on the installed system: its top
// level is rootfs/ (the slot files plus the deployment WAL that describes them), efi/
// and firmware/ (mountpoints the initramfs needs, which the read-only erofs root cannot
// host). The WAL is taken from the live ESP so the recorded version matches the image
// actually written.
func setupSystem(part, erofs, hash, esp string) error {
	if err := run("mkfs.ext4", "-q", "-L", "atom-system", "-F", part); err != nil {
		return err
	}
	mnt, err := os.MkdirTemp("", "atom-system")
	if err != nil {
		return err
	}
	defer os.RemoveAll(mnt)
	if err := run("mount", "-t", "ext4", part, mnt); err != nil {
		return err
	}
	defer run("umount", mnt)

	for _, d := range []string{"rootfs", "efi", "firmware"} {
		if err := os.MkdirAll(filepath.Join(mnt, d), 0o755); err != nil {
			return err
		}
	}
	slots := filepath.Join(mnt, "rootfs")
	if err := run("dd", "if="+erofs, "of="+filepath.Join(slots, "rootfs-active.erofs"), "bs=4M", "conv=fsync"); err != nil {
		return err
	}
	if err := run("dd", "if="+hash, "of="+filepath.Join(slots, "rootfs-active.hash"), "bs=4M", "conv=fsync"); err != nil {
		return err
	}
	return copyDeployment(esp, slots)
}

// copyDeployment lands the deployment WAL (and its backup copy) beside the slot files.
// The live ESP is mounted read-only when it is not already reachable at /boot/efi.
func copyDeployment(esp, slots string) error {
	src := "/boot/efi/EFI/atom/deployment.json"
	if _, err := os.Stat(src); err != nil {
		mnt, err := os.MkdirTemp("", "atom-esp")
		if err != nil {
			return err
		}
		defer os.RemoveAll(mnt)
		if err := run("mount", "-t", "vfat", "-o", "ro", esp, mnt); err != nil {
			return err
		}
		defer run("umount", mnt)
		src = filepath.Join(mnt, "EFI/atom/deployment.json")
	}
	b, err := os.ReadFile(src)
	if err != nil {
		return fmt.Errorf("deployment.json: %w", err)
	}
	if err := os.WriteFile(filepath.Join(slots, "deployment.json"), b, 0o644); err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(slots, "deployment.json.bak"), b, 0o644)
}

// sourceMB sizes a source that may be either a whole partition (the .iso still carries
// the root image raw) or a plain file (the .img carries it as a slot file).
func sourceMB(src string) (int64, error) {
	fi, err := os.Stat(src)
	if err != nil {
		return 0, err
	}
	if fi.Mode()&os.ModeDevice != 0 {
		return mibOfDev(src)
	}
	return mibOf(fi.Size()), nil
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

// fileExists reports whether path is a regular file.
func fileExists(path string) bool {
	fi, err := os.Stat(path)
	return err == nil && fi.Mode().IsRegular()
}

// mountedDevice returns the device backing a mountpoint, empty when not mounted.
func mountedDevice(mnt string) string {
	b, err := os.ReadFile("/proc/mounts")
	if err != nil {
		return ""
	}
	for _, ln := range strings.Split(string(b), "\n") {
		f := strings.Fields(ln)
		if len(f) >= 2 && f[1] == mnt {
			return f[0]
		}
	}
	return ""
}
