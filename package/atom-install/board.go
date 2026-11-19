package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"

	devices "github.com/singularityos-lab/sinty-devices"
	"github.com/singularityos-lab/sinty-devices/profile"
)

const (
	espType  = "C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
	dataType = "0FC63DAF-8483-4772-8E79-3D69D8477DE4"
	dataName = "atom-data"
)

var catalogProfiles = devices.Profiles

var compatiblePath = "/proc/device-tree/compatible"

var sysBlock = "/sys/class/block"

type boardProfile struct {
	Name    string
	ESP     string
	Replace []string
}

type diskPart struct {
	Num   int
	Dev   string
	Label string
	Start int64
	Size  int64
}

type installTarget struct {
	ESP    string
	ESPNum int
	Data   string
}

type installPlan struct {
	Layout string   `json:"layout"`
	Board  string   `json:"board,omitempty"`
	Erase  []string `json:"erase,omitempty"`
	Keep   []string `json:"keep,omitempty"`
}

var firmwareLabels = map[string]bool{
	"xbl": true, "xbl_config": true, "tz": true, "abl": true, "aboot": true, "sbl1": true,
	"rpm": true, "hyp": true, "keymaster": true, "devcfg": true, "uefi": true, "uefi_dtb": true,
	"uefisecapp": true, "qupfw": true, "cmnlib": true, "cmnlib64": true, "modem": true,
	"modemst1": true, "modemst2": true, "fsg": true, "dsp": true, "bluetooth": true,
	"mb1": true, "mb2": true, "mts-mb1": true, "bpmp-fw": true, "cpu-bootloader": true,
	"secure-os": true, "uboot": true, "u-boot": true, "spl": true, "idbloader": true,
}

func firmwareLabel(label string) bool {
	l := strings.ToLower(label)
	for _, p := range []string{"a_", "b_"} {
		if strings.HasPrefix(l, p) {
			l = l[len(p):]
		}
	}
	for _, s := range []string{"_a", "_b"} {
		l = strings.TrimSuffix(l, s)
	}
	return firmwareLabels[l]
}

func parseCompatible(b []byte) []string {
	var out []string
	for _, s := range strings.Split(string(b), "\x00") {
		if s = strings.TrimSpace(s); s != "" {
			out = append(out, s)
		}
	}
	return out
}

func matchBoard(profiles []*profile.Profile, compat []string, arch string) *boardProfile {
	for _, p := range profiles {
		if p.Install.Method != "installer-stick" || p.Arch != arch || !p.MatchesCompatible(compat) {
			continue
		}
		return &boardProfile{Name: p.Vendor + " " + p.Model, ESP: p.Install.ESP, Replace: p.Install.Replace}
	}
	return nil
}

func machineBoard() (*boardProfile, error) {
	b, err := os.ReadFile(compatiblePath)
	if err != nil {
		return nil, nil
	}
	profiles, err := catalogProfiles()
	if err != nil {
		return nil, fmt.Errorf("device catalog: %w", err)
	}
	return matchBoard(profiles, parseCompatible(b), machineArch()), nil
}

func readSysInt(path string) (int64, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return 0, err
	}
	return strconv.ParseInt(strings.TrimSpace(string(b)), 10, 64)
}

func diskParts(disk string) ([]diskPart, error) {
	base := filepath.Join(sysBlock, filepath.Base(disk))
	entries, err := os.ReadDir(base)
	if err != nil {
		return nil, err
	}
	var out []diskPart
	for _, e := range entries {
		dir := filepath.Join(base, e.Name())
		num, err := readSysInt(filepath.Join(dir, "partition"))
		if err != nil {
			continue
		}
		start, err := readSysInt(filepath.Join(dir, "start"))
		if err != nil {
			return nil, err
		}
		size, err := readSysInt(filepath.Join(dir, "size"))
		if err != nil {
			return nil, err
		}
		p := diskPart{Num: int(num), Dev: filepath.Join("/dev", e.Name()), Start: start, Size: size}
		if ue, err := os.ReadFile(filepath.Join(dir, "uevent")); err == nil {
			for _, ln := range strings.Split(string(ue), "\n") {
				if v, ok := strings.CutPrefix(ln, "PARTNAME="); ok {
					p.Label = v
				}
			}
		}
		out = append(out, p)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Num < out[j].Num })
	return out, nil
}

func guardWholeDisk(parts []diskPart) error {
	var fw []string
	for _, p := range parts {
		if firmwareLabel(p.Label) {
			fw = append(fw, p.Label)
		}
	}
	if len(fw) > 0 {
		return fmt.Errorf("the disk carries the board firmware (%s) and no board profile matches this machine; erasing it would leave the board unable to start", strings.Join(fw, ", "))
	}
	return nil
}

func boardLayout(parts []diskPart, b *boardProfile) (esp diskPart, gone []diskPart, err error) {
	byLabel := map[string]diskPart{}
	for _, p := range parts {
		if _, dup := byLabel[p.Label]; dup && p.Label != "" {
			return esp, nil, fmt.Errorf("%s: partition label %q is not unique", b.Name, p.Label)
		}
		byLabel[p.Label] = p
	}
	esp, ok := byLabel[b.ESP]
	if !ok {
		return esp, nil, fmt.Errorf("%s: the disk has no %q partition", b.Name, b.ESP)
	}
	replace := b.Replace
	if p, ok := byLabel[dataName]; ok && p.Label != "" {
		replace = []string{dataName}
	}
	for _, l := range replace {
		p, ok := byLabel[l]
		if !ok {
			return esp, nil, fmt.Errorf("%s: the disk has no %q partition", b.Name, l)
		}
		if firmwareLabel(l) || l == b.ESP {
			return esp, nil, fmt.Errorf("%s: refusing to replace %q", b.Name, l)
		}
		gone = append(gone, p)
	}
	sort.Slice(gone, func(i, j int) bool { return gone[i].Start < gone[j].Start })
	for i := 1; i < len(gone); i++ {
		if gone[i-1].Start+gone[i-1].Size != gone[i].Start {
			return esp, nil, fmt.Errorf("%s: %q and %q are not contiguous", b.Name, gone[i-1].Label, gone[i].Label)
		}
	}
	for _, p := range parts {
		for _, g := range gone {
			if p.Num != g.Num && p.Start < g.Start+g.Size && g.Start < p.Start+p.Size {
				return esp, nil, fmt.Errorf("%s: %q overlaps %q", b.Name, p.Label, g.Label)
			}
		}
	}
	return esp, gone, nil
}

func dataScript(gone []diskPart) string {
	last := gone[len(gone)-1]
	return fmt.Sprintf("start=%d, size=%d, type=%s, name=%s\n", gone[0].Start, last.Start+last.Size-gone[0].Start, dataType, dataName)
}

func boardDisk(parts []diskPart, b *boardProfile) bool {
	for _, p := range parts {
		if b != nil && p.Label == b.ESP {
			return true
		}
	}
	return false
}

func planFor(dev string, key bool) (installPlan, *boardProfile, error) {
	parts, err := diskParts(dev)
	if err != nil {
		return installPlan{}, nil, err
	}
	var b *boardProfile
	if !key {
		if b, err = machineBoard(); err != nil {
			return installPlan{}, nil, err
		}
	}
	if !boardDisk(parts, b) {
		b = nil
	}
	if b == nil {
		if err := guardWholeDisk(parts); err != nil {
			return installPlan{}, nil, err
		}
		return installPlan{Layout: "disk"}, nil, nil
	}
	esp, gone, err := boardLayout(parts, b)
	if err != nil {
		return installPlan{}, nil, err
	}
	pl := installPlan{Layout: "board", Board: b.Name, Erase: []string{esp.Label}}
	for _, g := range gone {
		pl.Erase = append(pl.Erase, g.Label)
	}
	for _, p := range parts {
		if p.Num != esp.Num && !containsPart(gone, p.Num) {
			pl.Keep = append(pl.Keep, p.Label)
		}
	}
	return pl, b, nil
}

func containsPart(parts []diskPart, num int) bool {
	for _, p := range parts {
		if p.Num == num {
			return true
		}
	}
	return false
}

func prepareDisk(dev string, espMB int64, key bool) (installTarget, error) {
	_, b, err := planFor(dev, key)
	if err != nil {
		return installTarget{}, err
	}
	if b == nil {
		sf := exec.Command("sfdisk", dev)
		sf.Stdin = strings.NewReader(partitionTable(espMB))
		if out, e := sf.CombinedOutput(); e != nil {
			return installTarget{}, fmt.Errorf("sfdisk: %w: %s", e, out)
		}
		_ = run("partprobe", dev)
		return installTarget{ESP: partName(dev, 1), ESPNum: 1, Data: partName(dev, 2)}, nil
	}
	parts, err := diskParts(dev)
	if err != nil {
		return installTarget{}, err
	}
	esp, gone, err := boardLayout(parts, b)
	if err != nil {
		return installTarget{}, err
	}
	if esp.Size*512 < espMB<<20 {
		return installTarget{}, fmt.Errorf("%s: the %q partition holds %d MiB, the system needs %d MiB", b.Name, esp.Label, esp.Size*512>>20, espMB)
	}
	del := []string{"--delete", dev}
	for _, g := range gone {
		del = append(del, strconv.Itoa(g.Num))
	}
	if err := run("sfdisk", del...); err != nil {
		return installTarget{}, err
	}
	sf := exec.Command("sfdisk", "--append", dev)
	sf.Stdin = strings.NewReader(dataScript(gone))
	if out, e := sf.CombinedOutput(); e != nil {
		return installTarget{}, fmt.Errorf("sfdisk --append: %w: %s", e, out)
	}
	_ = run("partprobe", dev)
	data, err := waitForLabel(dev, dataName)
	if err != nil {
		return installTarget{}, err
	}
	return installTarget{ESP: esp.Dev, ESPNum: esp.Num, Data: data}, nil
}

func waitForLabel(dev, label string) (string, error) {
	for i := 0; i < 20; i++ {
		parts, err := diskParts(dev)
		if err == nil {
			for _, p := range parts {
				if p.Label == label {
					return p.Dev, nil
				}
			}
		}
		time.Sleep(250 * time.Millisecond)
	}
	return "", fmt.Errorf("%s: partition %q did not appear", dev, label)
}

func machineArch() string {
	if runtime.GOARCH == "arm64" {
		return "aarch64"
	}
	return "x86_64"
}
