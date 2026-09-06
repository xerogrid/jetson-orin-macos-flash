#!/usr/bin/env bash
# Guest: image generation only; no storage writes to the Jetson.
set -euo pipefail
source /home/flash/load-target-profile.sh
cd /home/flash/jetson/Linux_for_Tegra
./tools/kernel_flash/l4t_initrd_flash.sh --no-flash --network usb0 --showlogs \
  jetson-xavier-nx-devkit-qspi internal
cp /home/flash/target.env /home/flash/target.env.qspi-prepared
