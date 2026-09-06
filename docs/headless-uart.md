# Headless console (no monitor, no Jetson keyboard)

You can skip a DisplayPort monitor and a USB keyboard **on the Orin**. You cannot skip a console.

The Jetson ISO installer still needs:

- Boot Manager (Esc), if the stick does not auto-boot
- **Y** within 30 seconds for the QSPI capsule update
- NVMe vs SD selection
- First-boot `oem-config` (user, password, network)

That input comes from a **3.3 V USB-TTL adapter** on header **J14**, with the keyboard on this Mac.

USB-C from Orin to Mac is **not** enough for UEFI or the ISO prompts. USB gadget serial (`ttyACM`, `192.168.55.1`) exists only after Jetson Linux is running.

| Stage | Monitor + USB keyboard | UART to this Mac | USB-C only |
|---|---|---|---|
| Write ISO on the Mac | not needed | not needed | not needed |
| Boot ISO and install to NVMe | yes | **yes** | no |
| First-boot user setup | yes | yes | **after** Linux is up |
| Fully unattended, no console | no | no | no |

## Adapter to buy

NVIDIA’s headless photos use this cable. Female Dupont ends push onto J14.

**Adafruit 954 — USB to TTL Serial Cable (3.3 V RX/TX)**  
$9.95, in stock as of 2026-09-06.

- [adafruit.com/product/954](https://www.adafruit.com/product/954)
- [Digi-Key 1528-2128-ND](https://www.digikey.com/en/products/detail/adafruit-industries-llc/954/6826688)
- [Amazon B00DJUHGHI](https://www.amazon.com/ADAFRUIT-Industries-954-Serial-Raspberry/dp/B00DJUHGHI)

Chip: Silicon Labs CP2102. Apple Silicon often needs the [CP210x VCP driver](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers). Allow the USB accessory if macOS asks.

### USB-C alternative (better Mac drivers)

**Adafruit 4331 — FTDI TTL-232 USB-C, 3.3 V logic**  
$19.95. [adafruit.com/product/4331](https://www.adafruit.com/product/4331)

FTDI usually enumerates on macOS without a extra driver. The cable ends in a 6-pin socket. You need three Dupont jumpers to J14.

Do **not** buy unlabeled CH340 “USB TTL” boards unless they state **3.3 V logic**. Many cheap ones are 5 V and can stress the header.

## Wiring (Adafruit 954)

Leave the **red** 5 V wire off. That pin can damage the Orin.

| Adafruit wire | J14 pin | Signal |
|---|---|---|
| Black | 7 | GND |
| White (RX into the Mac) | 4 | UART TX on the Orin |
| Green (TX out of the Mac) | 3 | UART RX on the Orin |
| Red | **do not connect** | 5 V from USB |

Logic is 3.3 V. Do not use a 5 V-only UART adapter.

## Open the console on this Mac

```bash
ls /dev/cu.usbserial* /dev/cu.usbmodem*
sudo screen /dev/cu.usbserial-XXXX 115200
```

115200 8N1. No hardware flow control.

1. Plug 19 V. Green LED next to USB-C should light.
2. Mash **Esc** in the `screen` window at the NVIDIA splash.
3. Open **Boot Manager**, pick the ISO USB stick.
4. Press **Y** when the capsule/QSPI prompt appears (30 second timeout).
5. Install onto NVMe or SD.
6. After Linux boots, finish `oem-config` on the same serial session.

To leave `screen`: `Ctrl-A` then `K`, then `Y`.
