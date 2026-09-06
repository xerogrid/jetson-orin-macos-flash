#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec ssh -i "$ROOT/.local/jetson-vm/id_ed25519" \
  -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10 \
  -o StrictHostKeyChecking=accept-new \
  -o "UserKnownHostsFile=$ROOT/.local/jetson-vm/known_hosts" \
  -p 22222 flash@127.0.0.1 "$@"
