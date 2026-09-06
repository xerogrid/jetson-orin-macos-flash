#!/usr/bin/env bash
# Write a Jetson ISO to a USB stick on macOS. Does not copy the file in Finder.
set -euo pipefail

ISO="${1:-}"
if [[ -z "${ISO}" || ! -f "${ISO}" ]]; then
  echo "Usage: $0 /path/to/jetsoninstaller-r39.2.1.iso" >&2
  echo >&2
  echo "Download (NVIDIA login may be required):" >&2
  echo "https://developer.nvidia.com/downloads/embedded/l4t/r39_release_v2.1/iso/jetsoninstaller-r39.2.1-2026-08-07-18-30-47-arm64.iso" >&2
  exit 1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This helper is for macOS." >&2
  exit 1
fi

echo "External disks:"
diskutil list external
echo
echo "Enter the whole-disk device to overwrite (example: /dev/disk4)."
echo "This erases that device. Internal disks are rejected."
read -r -p "Device: " DISK

if [[ ! "${DISK}" =~ ^/dev/disk[0-9]+$ ]]; then
  echo "Expected /dev/diskN." >&2
  exit 1
fi

if [[ ! -e "${DISK}" ]]; then
  echo "No such device: ${DISK}" >&2
  exit 1
fi

INTERNAL="$(diskutil info / | awk -F': *' '/Device Node/{print $2; exit}')"
if [[ "${DISK}" == "${INTERNAL}" ]]; then
  echo "Refusing to write the boot disk (${INTERNAL})." >&2
  exit 1
fi

PROTOCOL="$(diskutil info "${DISK}" | awk -F': *' '/Protocol/{print $1$2; exit}')"
echo "Target: ${DISK}"
diskutil info "${DISK}" | awk -F': *' '/Device \/ Media Name|Protocol|Disk Size|Internal/{print}'
echo
read -r -p "Type ERASE to write ${ISO} to ${DISK}: " CONFIRM
if [[ "${CONFIRM}" != "ERASE" ]]; then
  echo "Aborted."
  exit 1
fi

diskutil unmountDisk "${DISK}"
RAW="${DISK/disk/rdisk}"
echo "Writing with dd to ${RAW} ..."
sudo dd if="${ISO}" of="${RAW}" bs=4m status=progress
sync
diskutil eject "${DISK}"
echo "Done. Plug this stick into a USB-A port on the Orin, then boot it from UEFI Boot Manager."
