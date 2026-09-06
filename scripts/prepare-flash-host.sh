#!/usr/bin/env bash
# Run as root inside the fresh x86 Ubuntu VM. No target storage is accessed.
set -euo pipefail
[[ $(uname -m) == x86_64 && $EUID == 0 ]]
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  usbutils sshpass abootimg binfmt-support binutils cpio cpp \
  device-tree-compiler dosfstools lbzip2 libxml2-utils nfs-kernel-server \
  openssl python3-yaml qemu-user-static rsync udev uuid-runtime whois \
  lz4 zstd python-is-python3 cloud-guest-utils "linux-modules-extra-$(uname -r)"
modprobe cdc_ether
modprobe rndis_host
echo 'Host dependencies ready; wait for this command to exit before rebooting.'
