#!/usr/bin/env bash
# Run inside the dedicated Ubuntu VM after NVIDIA apply_binaries.sh succeeds.
# Configures the staged image only; this does not flash the Jetson.
set -euo pipefail
[[ $EUID == 0 && "${1:-}" == --accept-nvidia-license ]] || {
  echo 'Run with sudo and --accept-nvidia-license after reviewing the NVIDIA license.' >&2; exit 2;
}
source /home/flash/target-login.env
[[ "$TARGET_USER" =~ ^[a-z][a-z0-9_-]{0,30}$ && "$TARGET_USER" != root ]]
[[ "$TARGET_HOSTNAME" =~ ^[a-z0-9][a-z0-9-]{0,62}$ ]]
[[ "$TARGET_TIMEZONE" != *..* && -f "/usr/share/zoneinfo/$TARGET_TIMEZONE" ]]
cd /home/flash/jetson/Linux_for_Tegra
[[ $(uname -m) == x86_64 && -f rootfs/etc/nv_tegra_release ]]
[[ -s /home/flash/xavier-password && -s /home/flash/xavier_ed25519.pub ]]
umask 077
if awk -F: -v user="$TARGET_USER" '$1 == user {found=1} END {exit !found}' rootfs/etc/passwd; then
  echo 'Staged user already exists; refusing to replace its credentials.' >&2; exit 1
fi
./tools/l4t_create_default_user.sh -u "$TARGET_USER" -n "$TARGET_HOSTNAME" \
  -p "$(< /home/flash/xavier-password)" --accept-license \
  > /home/flash/xavier-user-setup.log 2>&1
uid=$(awk -F: -v user="$TARGET_USER" '$1 == user {print $3}' rootfs/etc/passwd)
gid=$(awk -F: -v user="$TARGET_USER" '$1 == user {print $4}' rootfs/etc/passwd)
[[ "$uid" =~ ^[0-9]+$ && "$gid" =~ ^[0-9]+$ ]]
install -d -m 700 -o "$uid" -g "$gid" "rootfs/home/$TARGET_USER/.ssh"
install -m 600 -o "$uid" -g "$gid" /home/flash/xavier_ed25519.pub \
  "rootfs/home/$TARGET_USER/.ssh/authorized_keys"
ln -sfn "/usr/share/zoneinfo/$TARGET_TIMEZONE" rootfs/etc/localtime
systemctl --root="$PWD/rootfs" enable ssh
echo "Staged user $TARGET_USER, hostname $TARGET_HOSTNAME, SSH key and $TARGET_TIMEZONE timezone."
