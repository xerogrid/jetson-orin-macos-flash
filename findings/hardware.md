# Hardware findings

Session date: 2026-09-06.

Current correction: the owner explicitly confirmed **Jetson Xavier NX Developer Kit**.
Use the Xavier NX/P3509 hardware instructions. The previous Orin identification
was incorrect; Orin-specific sections below are historical reference only.
The owner reports an 8 GB microSD, a 4 TB 2280 NVMe, a USB keyboard and webcam,
and no monitor. Recovery is now confirmed on DARKSTAR as NVIDIA Corp. APX,
USB ID `0955:7e19`. The owner identified the earlier failure as bridging the wrong
header; detection succeeded after using the correct J14 recovery pins.

## Identity checks

| Clue | Original Nano 4GB | Xavier NX DevKit | Orin Nano DevKit | Orin NX on P3509 |
|---|---|---|---|---|
| Power jumper J48 | Yes, next to 5 V barrel | No | No | No |
| Barrel voltage | 5 V, 2.1 mm | 19 V, 2.5 mm | 19 V, 2.5 mm | 19 V, 2.5 mm |
| Recovery USB | Micro-USB | Micro-USB | **USB-C (data only)** | Micro-USB |
| USB-A ports | Host only | Host only | Host only | Host only |
| microSD | Underside of module | Underside of module (devkit SOM) | Module edge (devkit SOM only) | None on production SOM |
| NVMe Key M | No (Key E is Wi-Fi) | Underside, optional | 2280 Key M | Underside Key M |
| J48 present | Yes | No | No | No |

Owner facts that ruled out original Nano:

- No J48.
- Using original barrel adapters (Xavier/Orin class is 19 V).
- Tried three NVMe drives.
- Stated no microSD on the kit (production Orin SOM has no slot; the DevKit SOM slot is on the module, not the carrier).

## Power (Orin Nano DevKit, carrier P3768)

- Jack: DC barrel, **5.5 × 2.5 mm**, center positive.
- Voltage: **19 V** (carrier accepts 9–20 V). NVIDIA supplies a 19 V brick.
- USB-C on this carrier is **data / recovery only**. It does not replace the barrel brick.
- Green LED next to USB-C means the board has power. It does not mean a host should see a USB device.

A 5 V Nano brick will not run Orin. A 19 V Orin/Xavier brick on an original 5 V Nano can kill that older board.

## Storage

- Official Orin Nano DevKit does **not** include storage in the box.
- Boot media is a **microSD** (devkit SOM) or an **M.2 Key M 2280 NVMe**.
- Production Orin Nano / Orin NX modules have **no microSD slot**.
- M.2 Key E is Wi-Fi, not NVMe.
- An unflashed NVMe does not make USB appear on a host.

## Ports that matter for a Mac

Use the recovery USB port only:

- Orin Nano DevKit carrier: **USB-C**.
- Xavier NX carrier (P3509) with Orin NX module: **micro-USB**.

Do not use the four USB-A ports. Those are host ports for keyboard, mouse, and flash drives.
