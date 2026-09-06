#!/usr/bin/env bash
# Boot the already prepared RAM-only recovery image; never install to storage.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bash "$ROOT/scripts/flash-vm-ssh.sh" \
  'lsusb -d 0955:7e19 && test -s /home/flash/jetson/Linux_for_Tegra/bootloader/boot0.img' \
  || { echo 'Xavier APX or prepared recovery image unavailable; nothing started.' >&2; exit 1; }
exec bash "$ROOT/scripts/flash-vm-ssh.sh" \
  'cd /home/flash/jetson/Linux_for_Tegra && sudo ./tools/kernel_flash/l4t_initrd_flash.sh --flash-only --initrd --network usb0 --showlogs'
