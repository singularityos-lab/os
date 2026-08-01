package main

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

func newInstallID() (string, error) {
	var id [16]byte
	if _, err := rand.Read(id[:]); err != nil {
		return "", fmt.Errorf("generate install ID: %w", err)
	}
	return hex.EncodeToString(id[:]), nil
}

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
	globs := []string{"/dev/vd*[0-9]", "/dev/sd*[0-9]", "/dev/sr[0-9]p[0-9]*", "/dev/nvme*p[0-9]*", "/dev/mmcblk*p[0-9]*"}
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

// parentDisk returns the whole-disk device that owns dev, using sysfs so SATA,
// NVMe and MMC partition naming are handled by the kernel rather than by string rules.
func parentDisk(dev string) string {
	path, err := filepath.EvalSymlinks(filepath.Join("/sys/class/block", filepath.Base(dev)))
	if err != nil {
		return ""
	}
	if _, err := os.Stat(filepath.Join(path, "partition")); err == nil {
		path = filepath.Dir(path)
	}
	return filepath.Join("/dev", filepath.Base(path))
}

// detectSources finds the live ESP, erofs root and verity hash partitions.
func detectSources(target string) (esp, erofs, hash string, err error) {
	// Three source layouts are supported: an installed/test image can expose the root
	// as a slot file on its mounted data partition, optical media expose files through
	// ISO9660, and disk images expose raw root and hash partitions. Prefer mounted
	// files when present, then probe raw partitions.
	const activeErofs = "/boot/rootfs/rootfs-active.erofs"
	const activeHash = "/boot/rootfs/rootfs-active.hash"
	const opticalErofs = "/var/.iso/live/rootfs.erofs"
	const opticalHash = "/var/.iso/live/rootfs.hash"
	// The initramfs mounts the source ESP before starting userspace. Reuse that device:
	// probing it by mounting it again read-only can fail because it is already mounted.
	esp = mountedDevice("/boot/efi")
	sourceDisk := parentDisk(esp)
	if fileExists(activeErofs) && fileExists(activeHash) {
		erofs, hash = activeErofs, activeHash
	} else if fileExists(opticalErofs) && fileExists(opticalHash) {
		erofs, hash = opticalErofs, opticalHash
	}
	for _, d := range candidatePartitions(target) {
		if sourceDisk != "" && parentDisk(d) != sourceDisk {
			continue
		}
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
	installID, err := newInstallID()
	die(err)
	espMB, err := mibOfDev(esp)
	die(err)

	// partition
	sf := exec.Command("sfdisk", dev)
	sf.Stdin = strings.NewReader(partitionTable(espMB))
	if out, e := sf.CombinedOutput(); e != nil {
		die(fmt.Errorf("sfdisk: %w: %s", e, out))
	}
	_ = run("partprobe", dev)

	die(run("dd", "if="+esp, "of="+partName(dev, 1), "bs=4M", "conv=fsync"))
	die(setupData(partName(dev, 2), erofs, hash, esp, installID))
	die(activateInstalledKernelcache(partName(dev, 1), installID))
	setUEFIEntry(dev) // best-effort

	fmt.Printf("atom-install: %s provisioned\n", dev)
}

// activateInstalledKernelcache replaces the live-only UKI copied with the source ESP.
// The installed UKI accepts slot files instead of waiting for raw removable partitions.
func activateInstalledKernelcache(esp, installID string) error {
	mnt, err := os.MkdirTemp("", "atom-esp-target")
	if err != nil {
		return err
	}
	defer os.RemoveAll(mnt)
	if err := run("mount", "-t", "vfat", esp, mnt); err != nil {
		return err
	}
	defer run("umount", mnt)

	dir := filepath.Join(mnt, "EFI", "atom")
	stateDir := filepath.Join(dir, "state")
	if err := os.MkdirAll(stateDir, 0o755); err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(stateDir, "install-id"), []byte(installID+"\n"), 0o644); err != nil {
		return err
	}
	pairs := [][2]string{
		{filepath.Join(dir, "kernelcache-install.efi"), filepath.Join(dir, "kernelcache-active.efi")},
		{filepath.Join(dir, "kernelcache-install.efi.sig"), filepath.Join(dir, "kernelcache-active.efi.sig")},
	}
	for _, pair := range pairs {
		if !fileExists(pair[0]) {
			return fmt.Errorf("installed kernelcache missing: %s", pair[0])
		}
	}
	for _, pair := range pairs {
		if err := os.Rename(pair[0], pair[1]); err != nil {
			return err
		}
	}
	return run("sync")
}

// setupData builds the one partition the installed system boots from: the root image
// and its verity hash as the active slot under boot/rootfs, the mountpoints the
// read-only erofs root cannot host, and the user directories that become /var. f2fs
// with encrypt so fscrypt can protect the user data -- the data, not the whole disk.
// .atom-var is what tells the init this is an installed system rather than a live
// medium, which is what arms the update daemon.
func setupData(part, erofs, hash, esp, installID string) error {
	if err := run("mkfs.f2fs", "-f", "-l", "atom-data", "-O", "encrypt,extra_attr", part); err != nil {
		return err
	}
	mnt, err := os.MkdirTemp("", "atom-data")
	if err != nil {
		return err
	}
	defer os.RemoveAll(mnt)
	if err := run("mount", "-t", "f2fs", part, mnt); err != nil {
		return err
	}
	defer run("umount", mnt)

	for _, d := range []string{
		"boot/rootfs", "boot/efi", "boot/firmware",
		"home", "etc-upper", "etc-work", "lib", "log", "cache", "spool", "tmp", "run",
	} {
		if err := os.MkdirAll(filepath.Join(mnt, d), 0o755); err != nil {
			return err
		}
	}
	if err := os.Chmod(filepath.Join(mnt, "tmp"), 0o1777); err != nil {
		return err
	}
	slots := filepath.Join(mnt, "boot/rootfs")
	if err := run("dd", "if="+erofs, "of="+filepath.Join(slots, "rootfs-active.erofs"), "bs=4M", "conv=fsync"); err != nil {
		return err
	}
	if err := run("dd", "if="+hash, "of="+filepath.Join(slots, "rootfs-active.hash"), "bs=4M", "conv=fsync"); err != nil {
		return err
	}
	if err := copyDeployment(esp, slots); err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(mnt, ".atom-var"), nil, 0o644); err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(mnt, ".atom-install-id"), []byte(installID+"\n"), 0o644); err != nil {
		return err
	}
	// First boot runs the OOBE; the greeter session takes over afterwards. The running
	// image's own config is the source: it tracks how the session is actually started
	// (today the greeter is a client of the persistent compositor, not a nested labwc),
	// and a copy generated here would freeze whatever that was when this was written.
	gd := filepath.Join(mnt, "etc-upper/greetd")
	if err := os.MkdirAll(gd, 0o755); err != nil {
		return err
	}
	live, err := os.ReadFile(liveGreetdConfig)
	if err != nil {
		return fmt.Errorf("read the live greetd config: %w", err)
	}
	return os.WriteFile(filepath.Join(gd, "config.toml"), []byte(installedGreetdConfig(string(live))), 0o644)
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
