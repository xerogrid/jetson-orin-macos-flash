# Why native macOS flash is blocked

Recorded before a workaround is chosen.

## NVIDIA official host

SDK Manager and the Jetson Linux flash scripts (`flash.sh`, `l4t_initrd_flash.sh`) require:

- x86_64 PC
- Ubuntu 20.04 or 22.04 (version depends on JetPack)
- Direct USB access to the APX device (`0955:*`)

This Mac is **arm64**. Those binaries do not run natively.

## USB

Force Recovery flash needs the host to talk USB2 to NVIDIA APX.

| Path | USB to APX |
|---|---|
| Native macOS | Sees the device if recovery is correct. Has no NVIDIA flash toolchain. |
| Docker Desktop on Mac | **No USB passthrough.** |
| Linux VM without USB passthrough | Tools run. Board is invisible. |
| Linux VM **with** USB passthrough | This is the usual workaround (Parallels, UTM, VMware). |
| x86 Linux box | Official path. |

## Related NVIDIA paths (not yet tried here)

These are not a solution in this repo yet. They are leads for the next step:

1. **Jetson ISO installer USB** (JetPack 7.2+ on Orin Nano DevKit). NVIDIA says you can write the ISO from Windows, macOS, or Linux with Etcher, then boot the Jetson from that USB stick and install to NVMe/SD on the target. That avoids host-side tegraflash.
2. **microSD image + Etcher** if the SOM has an SD slot. That is first-boot, not NVMe recovery flash.
3. **Parallels Ubuntu x86_64 VM** on this Mac, USB passthrough of the APX device, then SDK Manager. This Mac already has Parallels virtual interfaces (`bridge100`, `bridge101`).
4. **UTM / QEMU** Ubuntu with USB passthrough. Extra pain on Apple Silicon because the flash tools are x86_64.
5. Third-party wrappers that run `tegraflash` in a Linux VM or container and claim macOS support (for example Peridio Avocado). Unverified here.

## What will not work

- `docker run` of SDK Manager on this Mac, expecting the Jetson on USB.
- Plugging USB-A on the Orin into the Mac.
- Flashing an NVMe in a USB enclosure with a generic Linux ISO and expecting Jetson boot firmware. Orin still needs the QSPI bootloader written with NVIDIA tools or the Jetson ISO installer.
- Using a Nano or Xavier NX SD image on Orin.
