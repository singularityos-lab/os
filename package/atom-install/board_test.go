package main

import (
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/singularityos-lab/sinty-devices/profile"
)

type fakePart struct {
	label       string
	start, size int64
}

func fakeDisk(t *testing.T, disk string, parts []fakePart) {
	t.Helper()
	root := t.TempDir()
	for i, p := range parts {
		name := fmt.Sprintf("%sp%d", disk, i+1)
		dir := filepath.Join(root, disk, name)
		if err := os.MkdirAll(dir, 0o755); err != nil {
			t.Fatal(err)
		}
		files := map[string]string{
			"partition": fmt.Sprint(i + 1),
			"start":     fmt.Sprint(p.start),
			"size":      fmt.Sprint(p.size),
			"uevent":    "MAJOR=259\nDEVTYPE=partition\nPARTN=" + fmt.Sprint(i+1) + "\nPARTNAME=" + p.label + "\n",
		}
		for f, v := range files {
			if err := os.WriteFile(filepath.Join(dir, f), []byte(v+"\n"), 0o644); err != nil {
				t.Fatal(err)
			}
		}
	}
	if err := os.WriteFile(filepath.Join(root, disk, "size"), []byte("61071360\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	old := sysBlock
	sysBlock = root
	t.Cleanup(func() { sysBlock = old })
}

func fakeMachine(t *testing.T, compat string, docs []string) {
	t.Helper()
	var profiles []*profile.Profile
	for _, d := range docs {
		p, err := profile.Parse([]byte(d))
		if err != nil {
			t.Fatal(err)
		}
		profiles = append(profiles, p)
	}
	path := filepath.Join(t.TempDir(), "compatible")
	if err := os.WriteFile(path, []byte(compat), 0o644); err != nil {
		t.Fatal(err)
	}
	oldProfiles, oldCompat := catalogProfiles, compatiblePath
	catalogProfiles = func() ([]*profile.Profile, error) { return profiles, nil }
	compatiblePath = path
	t.Cleanup(func() { catalogProfiles, compatiblePath = oldProfiles, oldCompat })
}

func unoQ() []fakePart {
	return []fakePart{
		{"xbl_a", 34, 7168},
		{"tz_a", 7202, 8192},
		{"uefi_a", 15394, 10240},
		{"modemst1", 25634, 4096},
		{"efi", 985408, 1048576},
		{"rootfs", 2033984, 20920568},
		{"userdata", 22954552, 38116774},
	}
}

func unoQProfile() string {
	return `{"schema":1,"id":"arduino/uno-q","vendor":"Arduino","model":"UNO Q","arch":"` + machineArch() + `",
"min_flash_version":"0.1.0","match":{"compatible":["arduino,imola"]},
"install":{"method":"installer-stick","esp":"efi","replace":["rootfs","userdata"]}}`
}

func TestShippedProfilesLoad(t *testing.T) {
	profiles, err := catalogProfiles()
	if err != nil {
		t.Fatal(err)
	}
	b := matchBoard(profiles, []string{"arduino,imola", "qcom,qcm2290", "qcom,qrb2210"}, "aarch64")
	if b == nil || b.Name != "Arduino UNO Q" || b.ESP != "efi" {
		t.Fatalf("UNO Q profile not matched: %+v", b)
	}
	if matchBoard(profiles, []string{"arduino,imola"}, "x86_64") != nil {
		t.Fatal("an aarch64 profile matched an x86_64 machine")
	}
}

func TestParseCompatible(t *testing.T) {
	got := parseCompatible([]byte("arduino,imola\x00qcom,qcm2290\x00qcom,qrb2210\x00"))
	if !reflect.DeepEqual(got, []string{"arduino,imola", "qcom,qcm2290", "qcom,qrb2210"}) {
		t.Fatalf("%q", got)
	}
}

func TestFirmwareLabel(t *testing.T) {
	for _, l := range []string{"xbl_a", "XBL_B", "tz_a", "abl_b", "uefi_dtb_a", "modemst1", "A_mb1", "B_mb2", "sbl1"} {
		if !firmwareLabel(l) {
			t.Errorf("%s must be firmware", l)
		}
	}
	for _, l := range []string{"ESP", "atom-data", "efi", "rootfs", "userdata", "", "tzdata"} {
		if firmwareLabel(l) {
			t.Errorf("%s must not be firmware", l)
		}
	}
}

func TestBoardPlanKeepsTheFirmware(t *testing.T) {
	fakeDisk(t, "mmcblk0", unoQ())
	fakeMachine(t, "arduino,imola\x00qcom,qcm2290\x00", []string{unoQProfile()})
	pl, b, err := planFor("/dev/mmcblk0", false)
	if err != nil {
		t.Fatal(err)
	}
	if b == nil || pl.Layout != "board" || pl.Board != "Arduino UNO Q" {
		t.Fatalf("plan %+v", pl)
	}
	if !reflect.DeepEqual(pl.Erase, []string{"efi", "rootfs", "userdata"}) {
		t.Fatalf("erase %v", pl.Erase)
	}
	if !reflect.DeepEqual(pl.Keep, []string{"xbl_a", "tz_a", "uefi_a", "modemst1"}) {
		t.Fatalf("keep %v", pl.Keep)
	}
	parts, _ := diskParts("/dev/mmcblk0")
	esp, gone, err := boardLayout(parts, b)
	if err != nil {
		t.Fatal(err)
	}
	if esp.Num != 5 || esp.Dev != "/dev/mmcblk0p5" {
		t.Fatalf("esp %+v", esp)
	}
	want := "start=2033984, size=59037342, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=atom-data\n"
	if got := dataScript(gone); got != want {
		t.Fatalf("script %q", got)
	}
}

func TestBoardReinstallReplacesTheDataPartition(t *testing.T) {
	parts := unoQ()[:5]
	parts = append(parts, fakePart{"atom-data", 2033984, 59037342})
	fakeDisk(t, "mmcblk0", parts)
	fakeMachine(t, "arduino,imola\x00", []string{unoQProfile()})
	pl, _, err := planFor("/dev/mmcblk0", false)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(pl.Erase, []string{"efi", "atom-data"}) {
		t.Fatalf("erase %v", pl.Erase)
	}
}

func TestWholeDiskRefusesBoardFirmwareWithoutAProfile(t *testing.T) {
	fakeDisk(t, "mmcblk0", unoQ())
	fakeMachine(t, "vendor,unknown-board\x00", []string{unoQProfile()})
	_, _, err := planFor("/dev/mmcblk0", false)
	if err == nil || !strings.Contains(err.Error(), "xbl_a") {
		t.Fatalf("want a refusal naming the firmware, got %v", err)
	}
}

func TestKeyTargetIgnoresTheBoardProfile(t *testing.T) {
	fakeDisk(t, "sda", []fakePart{{"efi", 2048, 1048576}, {"rootfs", 1050624, 4000000}})
	fakeMachine(t, "arduino,imola\x00", []string{unoQProfile()})
	pl, b, err := planFor("/dev/sda", true)
	if err != nil {
		t.Fatal(err)
	}
	if b != nil || pl.Layout != "disk" {
		t.Fatalf("plan %+v", pl)
	}
}

func TestPCDiskUsesTheWholeDisk(t *testing.T) {
	fakeDisk(t, "nvme0n1", []fakePart{{"EFI system partition", 2048, 532480}, {"Basic data partition", 534528, 900000000}})
	fakeMachine(t, "", nil)
	pl, b, err := planFor("/dev/nvme0n1", false)
	if err != nil || b != nil || pl.Layout != "disk" {
		t.Fatalf("plan %+v %v", pl, err)
	}
}

func TestBoardLayoutRejectsGaps(t *testing.T) {
	parts := []diskPart{
		{Num: 1, Label: "efi", Start: 100, Size: 100},
		{Num: 2, Label: "rootfs", Start: 200, Size: 100},
		{Num: 3, Label: "keep", Start: 300, Size: 50},
		{Num: 4, Label: "userdata", Start: 350, Size: 100},
	}
	b := &boardProfile{Name: "t", ESP: "efi", Replace: []string{"rootfs", "userdata"}}
	if _, _, err := boardLayout(parts, b); err == nil || !strings.Contains(err.Error(), "contiguous") {
		t.Fatalf("got %v", err)
	}
}

func TestBoardLayoutRefusesToReplaceFirmware(t *testing.T) {
	parts := []diskPart{
		{Num: 1, Label: "efi", Start: 100, Size: 100},
		{Num: 2, Label: "tz_a", Start: 200, Size: 100},
	}
	b := &boardProfile{Name: "t", ESP: "efi", Replace: []string{"tz_a"}}
	if _, _, err := boardLayout(parts, b); err == nil {
		t.Fatal("replacing firmware must be refused")
	}
}
