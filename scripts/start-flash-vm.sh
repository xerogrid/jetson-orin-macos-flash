#!/usr/bin/env bash
# Launch the dedicated x86 Ubuntu flashing VM. No flash command runs on startup.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VM_DIR="$ROOT/.local/jetson-vm"
for arg in "$@"; do
  if [[ "$arg" == "-daemonize" ]]; then
    echo 'QEMU -daemonize crashes in the macOS Objective-C runtime on this host.' >&2
    echo 'Run this script without -daemonize and keep that Terminal window open.' >&2
    exit 2
  fi
done
exec /opt/homebrew/bin/qemu-system-x86_64 \
  -name jetson-flash-host \
  -machine q35 -accel tcg,thread=multi -cpu max -smp 4 -m 8192 \
  -drive "file=$VM_DIR/ubuntu.qcow2,format=qcow2,if=virtio" \
  -drive "file=$VM_DIR/seed.iso,format=raw,media=cdrom,readonly=on" \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:22222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -device usb-ehci,id=ehci \
  -device usb-host,id=jetson,bus=ehci.0,vendorid=0x0955,guest-reset=false \
  -display none -serial "file:$VM_DIR/serial.log" \
  -qmp "unix:$VM_DIR/qmp.sock,server=on,wait=off" \
  -pidfile "$VM_DIR/qemu.pid" \
  "$@"
