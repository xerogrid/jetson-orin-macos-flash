# Jetson Xavier NX bring-up from macOS

**Start here:** [Apple Silicon reproduction runbook](docs/apple-silicon-runbook.md).
It includes verified downloads, fresh private credentials, QEMU host setup,
RAM-only device inspection, guarded QSPI/NVMe flashing, expansion and reboot
verification. The working Xavier NX boots L4T R35.6.4 from its full 4 TB NVMe.
No private keys, passwords, VM disks or flash images belong in Git.

Next project: [Droid Foundry Pit Droid vision handoff](docs/pit-droid-vision-handoff.md).

## Current hardware correction — 2026-09-06

The owner has confirmed a **Jetson Xavier NX Developer Kit**, superseding the
Orin identification in the historical notes below. Do not use the Orin JetPack
7.2 ISO procedure or `scripts/write-jetson-iso.sh` for this board.

- Owner identifies the developer kit as Xavier NX (P3668-0000 module on P3509 carrier).
- Recovery connection: **Micro-USB** to the host; J14 pins **9 and 10** bridged during power-on.
- **Recovery confirmed on DARKSTAR: NVIDIA Corp. APX, USB ID 0955:7e19.**
  Earlier attempts bridged the wrong header; using the correct J14 pins resolved detection.
- Installed storage reported by owner: **8 GB microSD and 4 TB M.2 2280 NVMe**.
- Intended install target: NVMe. The 8 GB card is too small for the standard JetPack installation.
- Software family: **JetPack 5.x / Jetson Linux r35**. NVIDIA lists JetPack 5.1.6;
  its SD route uses the 5.1.5 image followed by an APT upgrade and may require a QSPI update.
- A dedicated **QEMU x86 Ubuntu 20.04 VM now runs on DARKSTAR** and sees APX.
  NVIDIA's tool read the chip ID successfully. The r35.6.4 root filesystem and
  headless SSH login are prepared. RAM upload succeeded and the target now
  enumerates as **Linux for Tegra (0955:7035)**. Recovery USB networking and
  target SSH now work with the VM running as administrator in the foreground.
  QSPI and the authorized 4 TB Crucial NVMe **flashed successfully**.
  The installed system boots from NVMe, accepts its saved SSH key, reaches
  GitHub over HTTPS, loads the NVIDIA GPU driver, and detects Logitech BRIO.
  The root filesystem was expanded to the full drive (3.6 TiB reported by Linux).
  See [current QEMU setup](docs/xavier-nx-qemu.md).
- The old NVMe EFI/exFAT `BC4` layout was replaced. The microSD was not flashed.

Sources: [NVIDIA r35 recovery instructions](https://docs.nvidia.com/jetson/archives/r35.6.0/DeveloperGuide/IN/QuickStart.html),
[JetPack 5.1.6](https://developer.nvidia.com/embedded/jetpack-sdk-516).

## Historical Orin notes — not applicable to the current board

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
