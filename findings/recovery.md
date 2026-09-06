# Force Recovery

This is the only USB path that proves the SoC is alive on a blank board.

## Orin Nano Developer Kit (P3768)

1. Unplug the 19 V brick.
2. Short **J14 pin 9 to pin 10** (`FC REC` to `GND`) under the module. A 2.54 mm jumper or a paperclip is enough.
3. Connect a **data** USB-C cable from the carrier USB-C port to the host. Not USB-A on the Jetson.
4. Plug in 19 V. The green LED should light.
5. Host should list NVIDIA APX.
6. Remove the jumper after the host sees the device.

If the board is already powered:

1. Short pins 9 and 10.
2. Momentarily short pins 7 and 8 (reset).
3. Remove the jumpers after APX appears.

## Expected USB IDs (`idVendor` 0x0955 = 2389)

| Board | Recovery PID | `lsusb` style ID |
|---|---|---|
| Orin Nano 8 GB | 7523 | `0955:7523` |
| Orin Nano 4 GB | 7623 | `0955:7623` |
| Orin NX 16 GB | 7323 | `0955:7323` |
| Orin NX 8 GB | 7423 | `0955:7423` |
| Xavier NX | 7e19 | `0955:7e19` |
| Original Nano (T210) | 7f21 | `0955:7f21` |

On macOS, look for `idVendor = 2389` in `ioreg -p IOUSB -l`, or product strings `NVIDIA`, `APX`, `Tegra`.

APX is not a mass-storage disk. Flash tools talk to it as a custom USB device.

## Xavier NX carrier with an Orin NX module

Same J14 9–10 short. Use the **micro-USB** port, not USB-C. Same 19 V barrel. No J48.
