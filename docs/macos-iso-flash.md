# Flash Orin from macOS (Jetson ISO)

This is NVIDIA’s supported path for JetPack 7.2 and later on the **Jetson Orin Nano Developer Kit**. The Mac writes a USB installer. The Orin boots that stick and installs Linux onto NVMe or microSD. The Mac never runs SDK Manager.

Official guide: [Orin Nano Quick Start](https://docs.nvidia.com/jetson/orin-nano-devkit/user-guide/latest/quick_start.html)

Download page: [JetPack downloads](https://developer.nvidia.com/embedded/jetpack/downloads)

ISO (JetPack 7.2.1 / L4T r39.2.1):

https://developer.nvidia.com/downloads/embedded/l4t/r39_release_v2.1/iso/jetsoninstaller-r39.2.1-2026-08-07-18-30-47-arm64.iso

NVIDIA may require a Developer login for that URL.

## What you need

| Item | Spec |
|---|---|
| Host | This Mac, 25 GB free |
| Installer media | USB flash drive, **16 GB or larger** |
| Target storage on the Orin | NVMe in M.2 Key M **or** 64 GB+ UHS-1 microSD in the **module** slot |
| Power | **19 V** barrel brick |
| Display | DisplayPort + USB keyboard, **or** UART on J14 (see [headless-uart.md](headless-uart.md)) |

Do **not** write the ISO to the microSD card. Write it to a USB stick. The installer then copies Jetson Linux onto NVMe or SD.

There is no more official Orin Nano SD-card image as of JetPack 7.2.

## Firmware gate

JetPack 7.2 ISO needs UEFI/QSPI **36.0 or newer**.

1. Plug DisplayPort and a keyboard, **or** a 3.3 V USB-TTL adapter on J14 ([headless-uart.md](headless-uart.md)).
2. Plug 19 V. Green LED next to USB-C should light.
3. Mash **Esc** at the NVIDIA splash (on the monitor or in `screen`).
4. Read the firmware version at the top of UEFI.

If the version is `36.x` or newer, continue.  
If it is older than `36.0`, use the [JetPack 6.x update path](https://docs.nvidia.com/jetson/orin-nano-devkit/user-guide/latest/update_firmware.html) first. That path is not a Mac-native tegraflash. It still needs bootable JetPack 6 media or a Linux flash host.

If the board never shows a splash or UEFI, the ISO path cannot start. Then you need Force Recovery (`0955:7523` / `7623`) and an **x86 Ubuntu** host. See `findings/recovery.md` and `findings/flash-blockers.md`.

## Write the installer on this Mac

Do not copy the `.iso` file onto the stick in Finder. Image the device.

### Option A — Balena Etcher

1. Install [Etcher](https://etcher.balena.io/#download-etcher).
2. Flash from file: the Jetson ISO.
3. Target: the USB stick only.
4. Enable validation.

### Option B — `dd` helper in this repo

```bash
# download the ISO (login cookie may be required)
curl -L -o ~/Downloads/jetsoninstaller-r39.2.1.iso \
  'https://developer.nvidia.com/downloads/embedded/l4t/r39_release_v2.1/iso/jetsoninstaller-r39.2.1-2026-08-07-18-30-47-arm64.iso'

# list removable disks, then write
./scripts/write-jetson-iso.sh ~/Downloads/jetsoninstaller-r39.2.1.iso
```

The script lists external disks and waits for an explicit `/dev/diskN`. It refuses internal disks.

## Install on the Orin

1. Seat NVMe (Key M 2280, underside) or a microSD in the **module** slot.
2. Plug the ISO USB stick into a **USB-A** port on the Orin.
3. Plug DisplayPort + keyboard.
4. Plug 19 V.
5. Press **Esc**, open **Boot Manager**, select the USB stick.
6. When the installer asks to update QSPI/capsule firmware, press **Y** within **30 seconds**. Missing this step fails the install.
7. Wait for two capsule-update passes. Reboots during this are normal.
8. At GRUB, choose **Install Jetson ISO r39.2.1**.
9. Select **NVMe** or **SD**. That disk is erased.
10. Reboot. Remove the installer stick. Finish oem-config.

## What this Mac cannot do

- Run SDK Manager or `l4t_initrd_flash.sh` natively (those are x86_64 Linux).
- Pass the Orin APX device into Docker Desktop.
- Recover a board that has no UEFI and never enumerates USB.

This host has Parallels Desktop, but the current VMs are not Ubuntu x86_64. USB recovery flash still needs a Linux x86 box or a USB-passthrough x86 VM.
