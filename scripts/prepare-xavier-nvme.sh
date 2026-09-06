#!/usr/bin/env bash
# Run inside the dedicated Ubuntu VM AFTER QSPI-only image generation.
# Generates images only. Does not erase or flash any connected device.
set -euo pipefail
source /home/flash/load-target-profile.sh
cmp /home/flash/target.env /home/flash/target.env.qspi-prepared
cd /home/flash/jetson/Linux_for_Tegra
test -s tools/kernel_flash/images/internal/flash.idx
./tools/kernel_flash/l4t_initrd_flash.sh \
  --no-flash --external-device nvme0n1p1 \
  -c tools/kernel_flash/flash_l4t_external.xml -S "${APP_SIZE_GIB}GiB" \
  --external-only --append --network usb0 --showlogs \
  jetson-xavier-nx-devkit external
cp /home/flash/target.env tools/kernel_flash/images/target.env.prepared
