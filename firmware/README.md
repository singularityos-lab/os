# Sinty firmware add-on factory

Builds the **signed, dm-verity-sealed firmware add-on bundles** that Sinty delivers
over OTA after install. The install image itself ships **base-only**; the factory
here produces the extra, hardware-detected add-ons as separate artifacts.

## Base vs add-on split

**Base survival firmware (stays baked in the Root, always present):**

- CPU microcode (all: intel and amd)
- Wi-Fi: `iwlwifi`, `ath`, `rtw`
- Base Intel display

This guarantees recovery always has network and display, on any supported machine.

**Add-on OTA bundles (built here, fetched only for detected hardware):**

| bundle   | source                                    | for                   |
|----------|-------------------------------------------|-----------------------|
| `nvidia` | proprietary GSP firmware from the NVIDIA `.run` | dedicated NVIDIA GPUs |
| `amd`    | `linux-firmware/amdgpu/` (AMD official)   | dedicated AMD GPUs    |

Each dedicated GPU is its own image. Extra Wi-Fi is deferred for now (`ath` and
`rtw` stay in the base); add a bundle to `BUNDLES` in `build-fw.sh` when that
changes.

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
