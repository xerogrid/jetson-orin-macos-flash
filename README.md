# Jetson Orin from macOS

Lab notes for flashing an NVIDIA Jetson Orin board from a Mac.

Owner: xerogrid (Brendan Clodfelter).  
Host: Apple Silicon Mac (arm64), macOS 27.

## Status

| Item | State |
|---|---|
| Hardware identity | Orin (confirmed by owner after Nano / Xavier NX mix-up) |
| USB live on this Mac | Not seen. No NVIDIA `0955` device. |
| Flash from macOS | **Not solved yet.** This repo records findings first. |

NVIDIA SDK Manager and `l4t_initrd_flash.sh` are **x86_64 Linux** tools. They do not run natively on macOS. Docker Desktop on Mac does not pass USB through to a Linux container. That is the core problem this repo exists to solve.

## Repo layout

```
README.md                 this file
findings/hardware.md      board identity, power, ports, storage
findings/recovery.md      Force Recovery steps and USB IDs
findings/macos-host.md    what this Mac actually saw
findings/flash-blockers.md why native macOS flash fails
```

## What “recognize” means

A blank Orin does not show up as a disk. A laptop only sees it when:

1. Force Recovery is on, and the **recovery USB port** is connected, or
2. Linux has booted and USB device mode is running.

Empty NVMe does not enumerate. USB-A host ports on the carrier never enumerate the SoC to a Mac.
