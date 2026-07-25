# Sinty firmware add-on factory

Builds the **signed, dm-verity-sealed GPU add-on bundles** Sinty fetches over OTA
after install, for hardware the base image does not cover.

## What the base image covers today

The base Root carries CPU microcode (intel + amd), Wi-Fi (`iwlwifi`, `ath`,
`rtw`), Intel display (`i915`) and **AMD** GPU firmware (`amdgpu`), so Intel and
AMD (including dedicated AMD GPUs) work out of the box. **NVIDIA is trimmed from
the base** (`scripts/trim-image.sh` drops the GSP blobs and nouveau): an NVIDIA
machine runs on its integrated GPU until the add-on below is installed.

The longer-term target is a base trimmed to survival firmware only (microcode,
Wi-Fi, base display), every dedicated GPU delivered as an add-on. That split is
not fully applied yet (AMD still ships in the base).

## Add-on bundles

| bundle   | carries | for |
|----------|---------|-----|
| `nvidia` | the **proprietary** driver (`nvidia.ko` + userspace + GSP), built and **bound to the shipped kernel version** | dedicated NVIDIA GPUs |
| `amd`    | `linux-firmware/amdgpu/` (redistributable) | dedicated AMD GPUs (also already in the base) |

A driver bundle is bound to the exact kernel it was built against: the boot path
refuses a bundle whose kernel does not match the running one, so a kernel update
invalidates the old bundle until the matching one is fetched.

**Status:** this factory builds the GSP firmware bundle today; the kernel-bound
proprietary NVIDIA driver bundle is still to be built (needs the licensed `.run`,
a kernel build tree, and NVIDIA hardware to certify). Add a bundle to `BUNDLES`
in `build-fw.sh` when adding hardware.

The NVIDIA GSP firmware is **NVIDIA-licensed**: the factory downloads the `.run`
and extracts `gsp_*.bin` **at build time**, into `.tools/` and the built bundle
only. It is never committed or pushed. AMD firmware is redistributable
(`linux-firmware`).

## What a bundle is

One directory the initramfs can verify and mount fail-open (never bricks):

```
<bundle>/
  firmware-active.img                erofs, unioned over the base at /usr/lib/firmware
  firmware-active.hash               dm-verity hash tree sidecar
  fw-manifest-active.json(.sig)      release-signed manifest naming the bundle
  fw-signing-cert-active.json(.sig)  root-signed signing cert
```

Trust chain, re-run offline at boot by `fw-verify` (baked in the initramfs, see
`mount_firmware` in `scripts/build-initramfs.sh`):

```
root.pub  ->  signing cert  ->  manifest  ->  firmware_verity_hash  ->  veritysetup open
```

A missing, tampered, or wrong-key anchor falls through to base survival firmware;
the add-on is never mounted unverified.

## Build

```
./build-fw.sh
```

Writes signed bundles under `out/<bundle>/` and self-verifies each with `fw-verify`
after building. `out/` and `.tools/` are gitignored.

Overrides (env):

- `NVIDIA_VERSION`: driver whose GSP firmware to bundle (default `latest`, the
  current production release). `NVIDIA_FW_DIR` reuses an already-extracted tree.
- `SIGNING_KEY`, `SIGNING_CERT`, `ROOT_PUB`: production injects the real
  cold-root-signed signing key and cert here. Defaults are AtomLoops' TEST keys.
- `URL_BASE`: the OTA feed each bundle will be fetched from.
- `LINUX_FIRMWARE`, `ATOMLOOPS`: source trees.

The signer and verifier (`atom-sign`, `fw-verify`) build from AtomLoops on first run.

## Runtime (already in os)

os is base-only and already carries the consumer side: `fw-verify` plus `root.pub`
baked in the initramfs, and `mount_firmware` (per-bundle verify, then veritysetup,
then overlay union, fail-open). Publishing a bundle to the OTA feed is all a device
needs to pick it up post-install; the OTA state machine (stage, confirm, rollback)
lives in AtomLoops (`otad`).

Keys here are **TEST** keys. Production signs with the real cold root, which never
lives in this repo.
