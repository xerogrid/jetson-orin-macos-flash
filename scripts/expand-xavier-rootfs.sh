#!/usr/bin/env bash
# Run on the INSTALLED Jetson. Explicit serial and sector count required.
set -euo pipefail
[[ $EUID == 0 && $(uname -m) == aarch64 && $# == 3 && "$1" == --expand-authorized-nvme ]] || {
  echo 'Usage: sudo bash expand-xavier-rootfs.sh --expand-authorized-nvme SERIAL SECTORS' >&2; exit 2;
}
[[ "$3" =~ ^[1-9][0-9]{0,11}$ ]]
[[ $(findmnt -n -o SOURCE /) == /dev/nvme0n1p1 && $(findmnt -n -o FSTYPE /) == ext4 ]]
serial=$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//' /sys/class/block/nvme0n1/device/serial)
[[ "$serial" == "$2" && $(blockdev --getsz /dev/nvme0n1) == "$3" ]]
[[ $(blockdev --getss /dev/nvme0n1) == 512 ]]
sfdisk --verify /dev/nvme0n1
# growpart exits 1 when there is no remaining space: in that case do not mutate.
growpart -N /dev/nvme0n1 1
growpart /dev/nvme0n1 1
resize2fs /dev/nvme0n1p1
tune2fs -m 1 /dev/nvme0n1p1
sfdisk --verify /dev/nvme0n1
df -h /
