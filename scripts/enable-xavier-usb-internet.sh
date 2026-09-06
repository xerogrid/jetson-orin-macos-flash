#!/usr/bin/env bash
# Run as root inside the dedicated VM after the installed Jetson boots.
# Temporary networking only; rerun after restarting the VM or USB interface.
set -euo pipefail
test "$(cat /sys/class/net/eth0/device/../idVendor)" = 0955
ip link set eth0 up
ip address replace 192.168.55.100/24 dev eth0
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -C POSTROUTING -s 192.168.55.0/24 -o enp0s2 -j MASQUERADE \
  || iptables -t nat -A POSTROUTING -s 192.168.55.0/24 -o enp0s2 -j MASQUERADE
ip -brief address show eth0
