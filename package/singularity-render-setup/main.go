// Command singularity-render-setup enables software GL rendering only when no hardware
// GPU driver is present (VMs: virtio-gpu without virgl, vkms, simpledrm). Real GPUs keep
// hardware rendering. It replaces the shell script so the boot path carries no /bin/sh.
package main

import (
	"os"
	"path/filepath"
	"strings"
)

// hwDrivers are the DRM kernel drivers that mean a real, hardware-accelerated GPU.
var hwDrivers = map[string]bool{
	"i915": true, "xe": true, "amdgpu": true, "radeon": true, "nouveau": true,
	"msm": true, "panfrost": true, "panthor": true, "v3d": true, "lima": true,
	"etnaviv": true, "tegra": true,
}

// hasHardwareGPU reports whether any /sys/class/drm card is bound to a hardware driver.
func hasHardwareGPU(drmGlob string) bool {
	cards, _ := filepath.Glob(drmGlob)
	for _, c := range cards {
		b, err := os.ReadFile(filepath.Join(c, "device", "uevent"))
		if err != nil {
			continue
		}
		for _, ln := range strings.Split(string(b), "\n") {
			if drv, ok := strings.CutPrefix(ln, "DRIVER="); ok {
				if hwDrivers[drv] || strings.HasPrefix(drv, "nova") {
					return true
				}
			}
		}
	}
	return false
}

const softwareEnv = "MESA_LOADER_DRIVER_OVERRIDE=kms_swrast\n" +
	"GSK_RENDERER=cairo\n" +
	"WLR_RENDERER=pixman\n"

func run(drmGlob, envPath string) int {
	if hasHardwareGPU(drmGlob) {
		return 0
	}
	f, err := os.OpenFile(envPath, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0o644)
	if err != nil {
		return 1
	}
	defer f.Close()
	if _, err := f.WriteString(softwareEnv); err != nil {
		return 1
	}
	return 0
}

func main() {
	os.Exit(run("/sys/class/drm/card[0-9]*", "/etc/environment"))
}
