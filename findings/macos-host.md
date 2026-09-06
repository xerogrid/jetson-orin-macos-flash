# What this Mac saw

Host: Xero Prime, Apple Silicon (`AppleT8132USBXHCI`), arm64, macOS 27.  
Scan time: 2026-09-06.

## USB devices present

| Device | Vendor:Product | Notes |
|---|---|---|
| Raspberry Pi USB Gadget | `2e8a:0013` | Interface `en10`, **link inactive** |
| Logitech USB Receiver | `046d:c548` | Mouse/keyboard dongle |

No NVIDIA vendor `0955`. No APX. No Tegra serial. No new `cu.usbmodem*` node.

Serial nodes were only:

- `/dev/cu.Bluetooth-Incoming-Port`
- `/dev/cu.debug-console`

Thunderbolt/USB4 receptacles had no extra device.

## Network gadget

`en10` is named **Raspberry Pi USB Gadget**. Carrier was down. Assigning `192.168.7.1/24` on the Mac did not bring the link up. This is unrelated to Orin.

## Recovery scans

Repeated USB, serial, and interface scans after the owner said a new Jetson was plugged in. The USB list did not change. No attach events in the two-minute system log window.

Conclusion: the Orin was not enumerating on this Mac during the session. Likely causes from the hardware notes: wrong USB port (USB-A), no Force Recovery jumper, no 19 V, or the SoC USB path is dead. Cables were reported as data-capable, so charge-only cable is a weaker explanation than port/jumper/power.
