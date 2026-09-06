# Jetson Orin from macOS

Lab notes for flashing an NVIDIA Jetson Orin board from a Mac.

Owner: xerogrid (Brendan Clodfelter).  
Host: Apple Silicon Mac (arm64), macOS 27.

## Status

| Item | State |
|---|---|
| Hardware identity | Orin (confirmed by owner after Nano / Xavier NX mix-up) |
| USB live on this Mac | Not seen. No NVIDIA `0955` device. |
| Flash from macOS | **Jetson ISO USB installer** (JetPack 7.2.1). Native SDK Manager is still impossible. |

NVIDIA SDK Manager and `l4t_initrd_flash.sh` stay **x86_64 Linux**. Do not use them on this Mac. Docker Desktop here has no USB passthrough.

The supported Mac path: write NVIDIA’s **Jetson ISO** to a USB stick, boot the Orin from that stick, install onto NVMe or microSD. See [docs/macos-iso-flash.md](docs/macos-iso-flash.md).

No monitor or USB keyboard on the Orin: use a **3.3 V USB-TTL** cable on J14. Buy [Adafruit 954](https://www.adafruit.com/product/954). Wiring and `screen` steps: [docs/headless-uart.md](docs/headless-uart.md).

```bash
./scripts/write-jetson-iso.sh ~/Downloads/jetsoninstaller-r39.2.1.iso
./scripts/scan-nvidia-usb.sh
```

## Repo layout

```
README.md                   this file
docs/macos-iso-flash.md     JetPack 7.2.1 ISO procedure on macOS
docs/headless-uart.md       no monitor; Adafruit 954 on J14
scripts/write-jetson-iso.sh image a USB stick with dd
scripts/scan-nvidia-usb.sh  look for NVIDIA APX on this Mac
findings/hardware.md        board identity, power, ports, storage
findings/recovery.md        Force Recovery steps and USB IDs
findings/macos-host.md      what this Mac actually saw
findings/flash-blockers.md  why SDK Manager cannot run here
```

## What “recognize” means

A blank Orin does not show up as a disk. A laptop only sees it when:

1. Force Recovery is on, and the **recovery USB port** is connected, or
2. Linux has booted and USB device mode is running.

Empty NVMe does not enumerate. USB-A host ports on the carrier never enumerate the SoC to a Mac.
