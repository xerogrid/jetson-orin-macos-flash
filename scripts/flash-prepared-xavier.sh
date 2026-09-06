#!/usr/bin/env bash
# Run inside the flashing VM. DESTRUCTIVE: installs prepared QSPI + NVMe images.
set -euo pipefail
source /home/flash/load-target-profile.sh
[[ "${1:-}" == "--erase-authorized-nvme" ]] || {
  echo 'Requires explicit --erase-authorized-nvme. Erases the target NVMe.' >&2
  exit 2
}
[[ "${2:-}" == "$EXPECTED_NVME_SERIAL" ]] || {
  echo 'Second argument must be the serial measured during RAM-only inspection.' >&2; exit 2;
}
cd /home/flash/jetson/Linux_for_Tegra
cmp /home/flash/target.env tools/kernel_flash/images/target.env.prepared
lsusb -d 0955:7e19
test -s bootloader/boot0.img
test -s tools/kernel_flash/images/external/system.img
# Reject any package containing SD/eMMC targets.
awk -F, '$2 !~ /^ 3:0:/ {bad=1} END {exit (bad || NR == 0)}' \
  tools/kernel_flash/images/internal/flash.idx
awk -F, '$2 !~ /^ 9:0:/ {bad=1} END {exit (bad || NR == 0)}' \
  tools/kernel_flash/images/external/flash.idx
grep -qx 'external_device=nvme0n1p1' tools/kernel_flash/images/external/flash.cfg
awk -F, -v bytes="$((APP_SIZE_GIB * 1024 * 1024 * 1024))" \
  '$2 ~ /^ 9:0:APP$/ {found=1; if ($4+0 != bytes) bad=1} END {exit (!found || bad)}' \
  tools/kernel_flash/images/external/flash.idx
echo "Erasing QSPI and the NVMe inspected as $EXPECTED_NVME_SERIAL. APX cannot recheck its disk serial."
./tools/kernel_flash/l4t_initrd_flash.sh --flash-only --network usb0 --showlogs
