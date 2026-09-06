#!/usr/bin/env bash
# Standard scp arguments; use flash@127.0.0.1:/home/flash/... for the guest.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VM_DIR="$ROOT/.local/jetson-vm"
exec scp -i "$VM_DIR/id_ed25519" -P 22222 \
  -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10 \
  -o StrictHostKeyChecking=accept-new -o "UserKnownHostsFile=$VM_DIR/known_hosts" "$@"
