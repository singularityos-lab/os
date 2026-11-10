package main

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
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

// mountTemp mounts with the given mount arguments on a fresh temporary directory.
func mountTemp(pattern string, args ...string) (string, error) {
	mnt, err := os.MkdirTemp("", pattern)
	if err != nil {
		return "", err
	}
	if err := run("mount", append(args, mnt)...); err != nil {
		os.Remove(mnt)
		return "", err
	}
	return mnt, nil
}

// release flushes the filesystem mounted at mnt, unmounts it and removes the empty
// mountpoint. It never removes recursively: a failed unmount must not turn into
// deleting the filesystem that is still mounted there. When something outside the
// installer keeps the mount busy, the holders are logged and the mount is detached
// lazily: the flush above already committed everything the installer wrote.
func release(mnt string) error {
	if err := run("sync", "-f", mnt); err != nil {
		return err
	}
	var err error
	for i := 0; i < 20; i++ {
		if err = run("umount", mnt); err == nil {
			return os.Remove(mnt)
		}
		time.Sleep(500 * time.Millisecond)
	}
	logKernel(fmt.Sprintf("%v; holders: %s", err, holders(mnt)))
	if lerr := run("umount", "-l", mnt); lerr != nil {
		return fmt.Errorf("%v; lazy: %v", err, lerr)
	}
	return os.Remove(mnt)
}

// holders lists the processes and mounts that keep mnt in use.
func holders(mnt string) string {
	var out []string
	inside := func(p string) bool { return p == mnt || strings.HasPrefix(p, mnt+"/") }
	procs, _ := filepath.Glob("/proc/[0-9]*")
	for _, pd := range procs {
		var why []string
		for _, l := range []string{"cwd", "root", "exe"} {
			if t, err := os.Readlink(filepath.Join(pd, l)); err == nil && inside(t) {
				why = append(why, l)
			}
		}
		fds, _ := filepath.Glob(filepath.Join(pd, "fd", "*"))
		for _, fd := range fds {
			if t, err := os.Readlink(fd); err == nil && inside(t) {
				why = append(why, "fd:"+t)
			}
		}
		if b, err := os.ReadFile(filepath.Join(pd, "maps")); err == nil && strings.Contains(string(b), mnt+"/") {
			why = append(why, "maps")
		}
		if len(why) > 0 {
			comm, _ := os.ReadFile(filepath.Join(pd, "comm"))
			out = append(out, fmt.Sprintf("%s(%s)[%s]", filepath.Base(pd), strings.TrimSpace(string(comm)), strings.Join(why, ",")))
		}
	}
	if b, err := os.ReadFile("/proc/self/mountinfo"); err == nil {
		for _, ln := range strings.Split(string(b), "\n") {
			f := strings.Fields(ln)
			if len(f) > 4 && strings.HasPrefix(f[4], mnt+"/") {
				out = append(out, "submount:"+f[4])
			}
		}
	}
	if len(out) == 0 {
		return "none found"
	}
	return strings.Join(out, " ")
}

// logKernel leaves a line in the kernel log, which the live media collects.
func logKernel(msg string) {
	fmt.Fprintln(os.Stderr, "atom-install:", msg)
	if f, err := os.OpenFile("/dev/kmsg", os.O_WRONLY, 0); err == nil {
		fmt.Fprintf(f, "atom-install: %s\n", msg)
		f.Close()
	}
}

// sizeOf reports the size of a regular file or a block device.
func sizeOf(path string) (int64, error) {
	fi, err := os.Stat(path)
	if err != nil {
		return 0, err
	}
	if fi.Mode().IsRegular() {
		return fi.Size(), nil
	}
	return deviceSizeBytes(path)
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
	key, from, dev, err := parseArgs(os.Args[1:])
	if err != nil {
		fmt.Fprintln(os.Stderr, "usage: atom-install [--key [--from DIR]] /dev/DISK")
		os.Exit(1)
	}
	if fi, err := os.Stat(dev); err != nil || fi.Mode()&os.ModeDevice == 0 {
		fmt.Fprintf(os.Stderr, "atom-install: %s is not a block device\n", dev)
		os.Exit(1)
	}

	var esp, erofs, hash string
	var rel releaseDir
	var wal []byte
	var espMB int64
	var sources []string
	if from != "" {
		rel, err = readRelease(from)
		die(err)
		erofs, hash, wal, espMB = rel.erofs(), rel.hash(), deploymentWAL(rel.version, rel.recovery), releaseESPMB
		sources = rel.sources()
		anchorSource = rel.dir
	} else {
		esp, erofs, hash, err = detectSources(dev)
		die(err)
		espMB, err = mibOfDev(esp)
		die(err)
		sources = []string{esp, erofs, hash}
	}
	installID, err := newInstallID()
	die(err)

	// partition
	sf := exec.Command("sfdisk", dev)
	sf.Stdin = strings.NewReader(partitionTable(espMB))
	if out, e := sf.CombinedOutput(); e != nil {
		die(fmt.Errorf("sfdisk: %w: %s", e, out))
	}
	_ = run("partprobe", dev)

	for _, src := range sources {
		n, err := sizeOf(src)
		die(err)
		copied.total += n
	}
	copied.add(0)
	if from != "" {
		die(buildESP(partName(dev, 1), rel))
	} else {
		die(copyData(esp, partName(dev, 1)))
	}
	die(setupData(partName(dev, 2), erofs, hash, esp, installID, key, wal))
	die(activateInstalledKernelcache(partName(dev, 1), installID))
	if !key {
		setUEFIEntry(dev) // best-effort
	}

	fmt.Printf("atom-install: %s provisioned\n", dev)
}

// activateInstalledKernelcache replaces the live-only UKI copied with the source ESP.
// The installed UKI accepts slot files instead of waiting for raw removable partitions.
func activateInstalledKernelcache(esp, installID string) (err error) {
	mnt, err := mountTemp("atom-esp-target", "-t", "vfat", esp)
	if err != nil {
		return err
	}
	defer func() {
		if rerr := release(mnt); err == nil {
			err = rerr
		}
	}()

	dir := filepath.Join(mnt, "EFI", "atom")
	stateDir := filepath.Join(dir, "state")
	if err := os.MkdirAll(stateDir, 0o755); err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(stateDir, "install-id"), []byte(installID+"\n"), 0o644); err != nil {
		return err
	}
	if err := forgetSourceMachine(stateDir); err != nil {
		return err
	}
	pairs := [][2]string{
		{filepath.Join(dir, "kernelcache-install.efi"), filepath.Join(dir, "kernelcache-active.efi")},
		{filepath.Join(dir, "kernelcache-install.efi.sig"), filepath.Join(dir, "kernelcache-active.efi.sig")},
	}
	return promoteKernelcache(pairs)
}

func forgetSourceMachine(stateDir string) error {
	if err := os.RemoveAll(filepath.Join(stateDir, "pin")); err != nil {
		return err
	}
	if err := os.Remove(filepath.Join(stateDir, "SINTYRESCUE.txt")); err != nil && !os.IsNotExist(err) {
		return err
	}
	return nil
}

func promoteKernelcache(pairs [][2]string) error {
	for _, pair := range pairs {
		if !fileExists(pair[0]) && !fileExists(pair[1]) {
			return fmt.Errorf("installed kernelcache missing: %s", pair[0])
		}
	}
	for _, pair := range pairs {
		if !fileExists(pair[0]) {
			continue
		}
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
func setupData(part, erofs, hash, esp, installID string, key bool, wal []byte) (err error) {
	if err := run("mkfs.f2fs", "-f", "-l", "atom-data", "-O", "encrypt,extra_attr", part); err != nil {
		return err
	}
	mnt, err := mountTemp("atom-data", "-t", "f2fs", part)
	if err != nil {
		return err
	}
	defer func() {
		if rerr := release(mnt); err == nil {
			err = rerr
		}
	}()

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
	if err := copyData(erofs, filepath.Join(slots, "rootfs-active.erofs")); err != nil {
		return err
	}
	if err := copyData(hash, filepath.Join(slots, "rootfs-active.hash")); err != nil {
		return err
	}
	if err := copyDeployment(esp, slots, wal); err != nil {
		return err
	}
	if err := copyAnchor(slots, anchorSource); err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(mnt, ".atom-var"), nil, 0o644); err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(mnt, ".atom-install-id"), []byte(installID+"\n"), 0o644); err != nil {
		return err
	}
	if key {
		if err := markPortable(mnt); err != nil {
			return err
		}
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
	if err := os.WriteFile(filepath.Join(gd, "config.toml"), []byte(installedGreetdConfig(string(live))), 0o644); err != nil {
		return err
	}
	if err := run("sync", "-f", mnt); err != nil {
		return err
	}
	return checkData(mnt, erofs, hash)
}

// checkData checks that the root image, its hash and the installed-system marker
// are in place on the data partition mounted at mnt.
func checkData(mnt, erofs, hash string) error {
	slots := filepath.Join(mnt, "boot/rootfs")
	for _, c := range [][2]string{{erofs, "rootfs-active.erofs"}, {hash, "rootfs-active.hash"}} {
		want, err := sizeOf(c[0])
		if err != nil {
			return err
		}
		fi, err := os.Stat(filepath.Join(slots, c[1]))
		if err != nil {
			return fmt.Errorf("installed data check: %w", err)
		}
		if fi.Size() != want {
			return fmt.Errorf("installed data check: %s is %d bytes, want %d", c[1], fi.Size(), want)
		}
	}
	for _, f := range []string{".atom-var", "boot/rootfs/deployment.json", "etc-upper/greetd/config.toml"} {
		if _, err := os.Stat(filepath.Join(mnt, f)); err != nil {
			return fmt.Errorf("installed data check: %w", err)
		}
	}
	return nil
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
func copyDeployment(esp, slots string, wal []byte) error {
	if wal != nil {
		return writeDeployment(slots, wal)
	}
	src := "/boot/efi/EFI/atom/deployment.json"
	if _, err := os.Stat(src); err != nil {
		mnt, err := mountTemp("atom-esp", "-t", "vfat", "-o", "ro", esp)
		if err != nil {
			return err
		}
		defer release(mnt)
		src = filepath.Join(mnt, "EFI/atom/deployment.json")
	}
	b, err := os.ReadFile(src)
	if err != nil {
		return fmt.Errorf("deployment.json: %w", err)
	}
	return writeDeployment(slots, b)
}

var anchorSource = "/boot/rootfs/release"

var anchorFiles = []string{"manifest.json", "manifest.json.sig", "signing-cert.json", "signing-cert.json.sig"}

func copyAnchor(slots, source string) error {
	b, err := os.ReadFile(filepath.Join(slots, "deployment.json"))
	if err != nil {
		return err
	}
	var d struct {
		RootFS struct {
			Current string `json:"current"`
		} `json:"rootfs"`
	}
	if err := json.Unmarshal(b, &d); err != nil || d.RootFS.Current == "" || strings.ContainsAny(d.RootFS.Current, "/\\") {
		return nil
	}
	src := source
	if !fileExists(filepath.Join(src, "manifest.json")) {
		src = filepath.Join(source, d.RootFS.Current)
	}
	for _, f := range anchorFiles {
		if !fileExists(filepath.Join(src, f)) {
			return nil
		}
	}
	dst := filepath.Join(slots, "release", d.RootFS.Current)
	if err := os.MkdirAll(dst, 0o755); err != nil {
		return err
	}
	for _, f := range anchorFiles {
		data, err := os.ReadFile(filepath.Join(src, f))
		if err != nil {
			return err
		}
		if err := os.WriteFile(filepath.Join(dst, f), data, 0o644); err != nil {
			return err
		}
	}
	return nil
}

func writeDeployment(slots string, b []byte) error {
	if err := os.WriteFile(filepath.Join(slots, "deployment.json"), b, 0o644); err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(slots, "deployment.json.bak"), b, 0o644)
}

func parseArgs(args []string) (key bool, from, dev string, err error) {
	for len(args) > 1 {
		switch {
		case args[0] == "--key":
			key, args = true, args[1:]
		case args[0] == "--from" && len(args) > 2:
			from, args = args[1], args[2:]
		default:
			return false, "", "", fmt.Errorf("unexpected %s", args[0])
		}
	}
	if len(args) != 1 || (from != "" && !key) {
		return false, "", "", fmt.Errorf("bad arguments")
	}
	return key, from, args[0], nil
}

func markPortable(mnt string) error {
	dir := filepath.Join(mnt, "lib", "sinty")
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(dir, "portable"), nil, 0o600)
}
