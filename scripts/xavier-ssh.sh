#!/usr/bin/env bash
# Connect after installation, through the local flashing VM's USB network.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VM_DIR="$ROOT/.local/jetson-vm"
TARGET_USER="${TARGET_USER:-$(if [[ -f "$VM_DIR/target-user" ]]; then cat "$VM_DIR/target-user"; else echo xerogrid; fi)}"
[[ "$TARGET_USER" =~ ^[a-z][a-z0-9_-]*$ ]]
exec ssh -i "$VM_DIR/xavier_ed25519" \
  -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=15 \
  -o StrictHostKeyChecking=accept-new \
  -o "UserKnownHostsFile=$VM_DIR/xavier-known-hosts" \
  -o "ProxyCommand=ssh -i '$VM_DIR/id_ed25519' -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=yes -o UserKnownHostsFile='$VM_DIR/known_hosts' -p 22222 -W %h:%p flash@127.0.0.1" \
  "$TARGET_USER@192.168.55.1" "$@"
