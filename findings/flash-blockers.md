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

## Chosen path (2026-09-06)

**Jetson ISO USB installer, written on this Mac.** Documented in `docs/macos-iso-flash.md`.

That is NVIDIA’s JetPack 7.2.1 first-time setup for Orin Nano DevKit when you do not have an Ubuntu x86 host. The Mac only images the stick. The Orin boots the stick and flashes NVMe/SD itself.

ISO: `jetsoninstaller-r39.2.1-2026-08-07-18-30-47-arm64.iso`

## Other paths (not used)

1. **microSD image + Etcher** — NVIDIA dropped Orin Nano SD images in JetPack 7.2. Do not write the ISO to SD.
2. **Parallels Ubuntu x86_64 + USB passthrough + SDK Manager** — this Mac has Parallels, but the VMs here are not Ubuntu x86_64. Apple Silicon makes x86 guests slow.
3. **UTM / QEMU** — same USB + x86 problem.
4. Third-party `tegraflash` wrappers (example: Peridio Avocado). Unverified here.

## What will not work

- `docker run` of SDK Manager on this Mac, expecting the Jetson on USB.
- Plugging USB-A on the Orin into the Mac.
- Flashing an NVMe in a USB enclosure with a generic Linux ISO and expecting Jetson boot firmware. Orin still needs the QSPI bootloader written with NVIDIA tools or the Jetson ISO installer.
- Using a Nano or Xavier NX SD image on Orin.
