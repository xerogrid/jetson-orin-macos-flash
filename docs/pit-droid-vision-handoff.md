# Pit Droid machine-vision field test

## Owner's intent

Use a Logitech Brio on the **Jetson Xavier NX Developer Kit** for machine
vision, routing movement through the Arduino Nano already used in the Pit
Droid head. Preserve the production PIR firmware and unrelated droids.

## Recovered implementation

- Active repository: `https://github.com/xerogrid/Droid-Foundry.git`.
- Existing local branch: `pit/vision-track`, commit
  `ff9156bad828c7a707d23d9c7519896e9206a902`.
- Separate Mac checkout: `/Users/xerogrid/Desktop/github/Droid-Foundry-vision`.
- Jetson checkout: `/home/xerogrid/Droid-Foundry`, same branch and commit.
- The branch was not present in fetched origin refs. It was transferred to
  the owner's Jetson using a verified Git bundle; no branch was pushed.
- Original Battle Droid checkout remains on `battle/convention`; its untracked
  Vision model/cache files were preserved.

Read `Pit Droid/Vision/README.md`, `WorkingVisionTrack.cpp`, and the `jetson/`
directory in the recovered checkout for the original design.

The Jetson detects a person, maintains a smoothed target lock, and sends
normalized pan/tilt errors using `T,dx,dy` over USB serial at **115200 baud**.
The Nano owns the servos and LEDs. Firmware includes travel limits, slew
limiting, a deadband, lost-target hold/home behavior and PIR fallback.
The documented Version 1 wiring uses D9 for vertical and D10 for horizontal
servos; this is not the Battle Droid's PCA9685 wiring.

## Verified on the Xavier

- QSPI/NVMe flash and clean reboot passed; root filesystem uses the full 4 TB
  NVMe (3.6 TiB reported). Saved-key SSH, DNS and HTTPS work through the Mac VM.
- `nvgpu` and `uvcvideo` are loaded. Video0–video3 identify as Logitech BRIO.
- Brio currently negotiates **480 Mbit/s (USB 2.0)**.
- Ten existing tracking-math/protocol tests pass on both Mac and Xavier.
- NumPy is present; OpenCV and pyserial are absent. No Arduino serial device
  was enumerated. Tests do not validate camera capture, inference or motion.

## Next implementation steps

1. Update original Jetson Nano/JetPack 4.6/Python 3.6 setup assumptions for
   Xavier NX / L4T R35.6.4 / Ubuntu 20.04. Fix service user and paths to `xerogrid`.
2. Install compatible vision dependencies and stage/verify model assets.
3. Run a bounded, headless **camera-only** test with serial disabled; measure
   frames, detector behavior and latency. The original preview needs a display.
4. Confirm the actual Nano wiring, servo travel and USB power/backfeed handling
   before connecting or uploading firmware. Opening serial can reset the Nano;
   this firmware homes servos at startup and enables PIR fallback by default.
5. Only then perform a deliberately enabled motion bench test. No camera
   capture, Arduino upload, serial connection or movement command has been
   performed during this bring-up. No tracking service was enabled.

The current SSH/internet route depends on the Mac's running VM; standalone
Wi-Fi/Ethernet remains to be configured for untethered field use. See
[Xavier setup and credentials location](xavier-nx-qemu.md).
