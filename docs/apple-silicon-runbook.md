# Xavier NX → NVMe from an Apple Silicon Mac

This packages the successful 2026-09-06 bring-up: Xavier NX **P3668-0000**
developer module/P3509 carrier, QSPI + Crucial 4 TB NVMe, headless SSH, untouched
8 GB microSD. It is a community QEMU workaround, not an NVIDIA-supported macOS
flashing host. The hardware workflow passed on one Mac; the newly automated
bootstrap has not yet been repeated end-to-end on a second Mac.

**Destructive checkpoint:** step 6 replaces QSPI firmware and all contents of
the identified Jetson NVMe. Back up anything needed first. No Mac physical disk
is attached to this VM. Do not use these board profiles for Orin, Nano, eMMC
Xavier modules, fused/custom-secure-boot boards, or custom carriers.

## 1. Host and verified downloads

Tested: Apple Silicon, macOS 27, Homebrew QEMU 11.1.1, Ubuntu 20.04 amd64,
kernel 5.4.0-216-generic, NVIDIA L4T R35.6.4. Budget at least 16 GB host RAM
and about 150 GB free host storage. TCG emulates x86; expect tens of minutes,
not native VM speed. Use external Jetson power and a data-capable Micro-USB
cable. Only one NVIDIA USB device may be connected: passthrough follows its
vendor ID across boot modes. The Brio connects to the Jetson's host USB port.

Install Homebrew separately if needed, then from a normal Terminal:

```bash
brew install qemu python
git clone https://github.com/xerogrid/jetson-orin-macos-flash.git
cd jetson-orin-macos-flash
python3 scripts/setup-flash-vm.py --target-user jetson --hostname xavier-nx --timezone UTC
```

The setup script downloads pinned images, verifies SHA-256, decompresses the
BSP/rootfs on the Mac, creates a 160 GB sparse VM overlay, a private NoCloud
seed, two independent SSH keys, and a random target password. It refuses an
existing VM or credentials; do not delete an existing installation to rerun it.
For a new independent setup use a separate clone/directory. For a read-only
download check: `python3 scripts/setup-flash-vm.py --verify-downloads`.

`config/downloads.json` pins immutable Canonical image 20250624 (hash verified
against Canonical SHA256SUMS) and NVIDIA's R35.6.4 archives (hashes of the
successfully used downloads, not a claim of vendor signature verification).
APT/Homebrew dependencies are not frozen; this is a reproducible procedure,
not a bit-for-bit build. Ubuntu 20.04 is a legacy flashing host: don't expose
its SSH port publicly, and review Ubuntu's extended security support needs.

## 2. Start the dedicated Linux host

In Terminal, leave this running in the foreground:

```bash
sudo bash scripts/start-flash-vm.sh
```

Enter the Mac password only in Terminal's sudo prompt. Do not use
`-daemonize`, AppleScript administrator launching, or start a second copy.
The VM uses EHCI USB 2 with `guest-reset=false`; root is needed to capture the
USB network gadget on macOS. If macOS asks to allow an accessory, approve the
known Jetson. In another Terminal, in the same repository:

```bash
bash scripts/flash-vm-ssh.sh 'cloud-init status --wait'
bash scripts/flash-vm-scp.sh scripts/prepare-flash-host.sh flash@127.0.0.1:/home/flash/
bash scripts/flash-vm-ssh.sh 'sudo bash /home/flash/prepare-flash-host.sh'
```

Initial SSH may need a few minutes. Wait for package installation/initramfs
generation to exit; do not reboot mid-install. SSH is bound to Mac loopback
port 22222. `linux-modules-extra-$(uname -r)` supplies the USB network drivers.

## 3. Stage NVIDIA BSP, rootfs and headless login

Review the license shipped with the [NVIDIA BSP](https://developer.nvidia.com/embedded/jetson-linux-r3564)
before the explicit acceptance command below. Copy only the public target key;
its private key stays on the Mac.

```bash
bash scripts/flash-vm-scp.sh .local/jetson-vm/downloads/jetson_linux_r35.6.4_aarch64.tar .local/jetson-vm/downloads/tegra_linux_sample-root-filesystem_r35.6.4_aarch64.tar flash@127.0.0.1:/home/flash/
bash scripts/flash-vm-scp.sh .local/jetson-vm/xavier-password .local/jetson-vm/xavier_ed25519.pub .local/jetson-vm/target-login.env scripts/configure-xavier-rootfs.sh scripts/load-target-profile.sh scripts/prepare-xavier-qspi.sh scripts/prepare-xavier-nvme.sh scripts/flash-prepared-xavier.sh scripts/enable-xavier-usb-internet.sh flash@127.0.0.1:/home/flash/
bash scripts/flash-vm-ssh.sh
```

Inside the VM, once on a fresh staging directory (don't extract over an existing
configured rootfs):

```bash
chmod 600 /home/flash/xavier-password /home/flash/target-login.env
mkdir -p /home/flash/jetson
cd /home/flash/jetson
tar -xpf /home/flash/jetson_linux_r35.6.4_aarch64.tar
cd Linux_for_Tegra
sudo tar -xpf /home/flash/tegra_linux_sample-root-filesystem_r35.6.4_aarch64.tar -C rootfs
sudo ./apply_binaries.sh
sudo bash /home/flash/configure-xavier-rootfs.sh --accept-nvidia-license
```

The user-setup log may contain credentials. Keep it private, like the VM disk
and generated rootfs/image. No automatic target login or motion is enabled.

## 4. RAM-only boot and identity inspection

With Jetson power disconnected, bridge **J14 pins 9–10** on the small 12-pin
button header under the module, connect Micro-USB to the Mac, apply the proper
Jetson power, then remove the bridge. Do not bridge the 40-pin GPIO header.
Use NVIDIA's [Xavier NX recovery diagram/instructions](https://docs.nvidia.com/jetson/archives/r35.6.0/DeveloperGuide/IN/QuickStart.html).

In the VM:

```bash
lsusb -d 0955:7e19
cd /home/flash/jetson/Linux_for_Tegra
sudo ./tools/kernel_flash/l4t_initrd_flash.sh --initrd --network usb0 --showlogs jetson-xavier-nx-devkit external
```

`--initrd` stops at RAM boot; this inspection does not install to storage.
Do not run a separate `tegrarcm_v2 --uid`: it can consume the fresh recovery
handshake. After RAM boot, USB changes to Linux for Tegra (observed 0955:7035).
In a second VM SSH session:

```bash
ip -brief link
sudo ip link set eth0 up
sshpass -p root ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/home/flash/recovery-known-hosts root@fe80::1%eth0
```

`root` is the temporary stock recovery password, not the installed login.
Confirm `eth0` is the NVIDIA USB interface (`cat
/sys/class/net/eth0/device/../idVendor` → `0955`) before using it. If the name
differs, substitute the measured name in recovery commands and the networking
helper; don't assign the USB subnet to the VM's Internet interface.

On the RAM-booted target (read-only):

```bash
tr '\0' '\n' < /proc/device-tree/model
tr '\0' '\n' < /proc/device-tree/chosen/ids
tr '\0' '\n' < /proc/device-tree/chosen/nvidia,sku
lsblk -b -o NAME,SIZE,MODEL,SERIAL,FSTYPE,UUID,PARTUUID,MOUNTPOINT
blockdev --getsz /dev/nvme0n1
blockdev --getss /dev/nvme0n1
cat /sys/class/block/nvme0n1/device/serial
```

Record the board FAB/revision, exact NVMe serial (trim surrounding spaces),
512-byte sector count, and microSD UUIDs. Stop if the module is not P3668-0000
or sector size isn't 512. Do not assume the sample 4 TB drive's identity applies
to yours. **Do not probe `reboot --help` here**: recovery's wrapper ignores its
arguments and reboots immediately. Leave target inspection with `exit`.

## 5. Generate QSPI + external-only images

On the Mac, copy `config/target.env.example` to
`.local/jetson-vm/target.env` and edit every `REPLACE...` value using step 4.
Keep `APP_SIZE_GIB=32` for the tested image size. For the successful hardware,
FAB was `300`, revision `E.0`; these are examples, not defaults for another kit.
The target profile is trusted shell configuration; never source an untrusted file.

```bash
bash scripts/flash-vm-scp.sh .local/jetson-vm/target.env flash@127.0.0.1:/home/flash/
bash scripts/flash-vm-ssh.sh 'sudo bash /home/flash/prepare-xavier-qspi.sh'
bash scripts/flash-vm-ssh.sh 'sudo bash /home/flash/prepare-xavier-nvme.sh'
```

These are NVIDIA `README_initrd_flash.txt` Workflow 11 Example 2: QSPI-only
internal image, then external NVMe append, with `BootOrderNvme.dtbo`. Neither
command flashes hardware. Allow roughly 20 minutes under emulation; a 32 GiB
sparse-image scan can appear quiet for several minutes. Don't change the
profile between phases. Rebuild both phases if the profile changes.

## 6. Explicit destructive flash

Confirm backups and ownership/authorization for the exact inspected NVMe.
Keep the same Jetson and drive connected. Power-cycle back into recovery as
in step 4, remove the bridge, and do not run UID probes. Replace SERIAL below
with the exact serial you measured:

```bash
bash scripts/flash-vm-ssh.sh 'sudo bash /home/flash/flash-prepared-xavier.sh --erase-authorized-nvme SERIAL'
```

The wrapper requires the serial acknowledgement, unchanged preparation
profile, an APX device, QSPI-only `3:0` and NVMe-only `9:0` flash indices, and
the expected APP image size. **APX cannot inspect the NVMe serial live**; this
is not cryptographic device binding. Never swap targets/drives after inspection.
The microSD is not an accepted flash target. Do not interrupt QSPI writes.
Observed flash time was about 9 minutes; wait for NVIDIA's final success.

On the tested 4 TB disk, NVIDIA initially generated a backup GPT near 2 TiB;
its target flash script repaired GPT to the actual drive end. Do not assume
that happened on yours: verify the resulting table before expansion.

## 7. Boot, expand and verify

Once the installed OS boots, run on the Mac:

```bash
bash scripts/flash-vm-ssh.sh 'sudo bash /home/flash/enable-xavier-usb-internet.sh'
bash scripts/xavier-ssh.sh 'uname -a; cat /etc/nv_tegra_release; findmnt /; lsblk -b; systemctl --failed'
```

SSH uses the generated target username and private key, through the VM. First
host keys are accepted and then pinned in private known-hosts files. Inspect
unexpected host-key changes; don't globally disable checking. The tested
installed gadget supplies route/DNS via `192.168.55.100`; VM NAT is scoped to
`192.168.55.0/24` and uplink `enp0s2` for this VM topology. Rerun the helper
after USB/VM restarts. For a changed topology, inspect interfaces first.

Install the expansion tool, transfer the guarded script, then run with the
same measured SERIAL and SECTORS. Password is piped privately for sudo, not
embedded in commands or committed. The expansion script intentionally refuses
non-NVMe root, wrong serial/capacity, non-ext4, or a broken partition table.

```bash
bash scripts/xavier-ssh.sh 'sudo -S -p "" apt-get update' < .local/jetson-vm/xavier-password
bash scripts/xavier-ssh.sh 'sudo -S -p "" apt-get install -y cloud-guest-utils' < .local/jetson-vm/xavier-password
bash scripts/xavier-ssh.sh 'umask 077; tee /tmp/expand-xavier-rootfs.sh >/dev/null' < scripts/expand-xavier-rootfs.sh
bash scripts/xavier-ssh.sh 'sudo -S -p "" bash /tmp/expand-xavier-rootfs.sh --expand-authorized-nvme SERIAL SECTORS' < .local/jetson-vm/xavier-password
bash scripts/xavier-ssh.sh 'sudo -S -p "" reboot' < .local/jetson-vm/xavier-password
```

Wait for reboot, reapply the VM USB networking helper, and verify again:

```bash
bash scripts/flash-vm-ssh.sh 'sudo bash /home/flash/enable-xavier-usb-internet.sh'
bash scripts/xavier-ssh.sh 'findmnt /; df -h /; lsblk -o NAME,SIZE,FSTYPE,UUID,PARTUUID; systemctl --failed; lsmod | egrep "nvgpu|uvcvideo"; curl -I --max-time 20 https://api.github.com'
```

Require root `/dev/nvme0n1p1`, expected full capacity (4 TB ≈ 3.6 TiB), working
saved-key SSH, no unexplained failed services, DNS/HTTPS, and unchanged microSD
UUIDs. `growpart` on an already-full partition exits without growing; don't
repeat the expansion just to test scripts. If the partition table check fails,
stop and diagnose it rather than forcing a repair blindly.

## Credentials, shutdown, troubleshooting

Everything private lives under ignored `.local/jetson-vm/`: `id_ed25519` (VM),
`xavier_ed25519` (target), `xavier-password`, known-hosts, seed, downloaded files,
VM disk, profiles and logs. Keys/password are generated mode 600; keep a secure
encrypted backup through your own password manager/backup system. They have
not been uploaded or backed up by this package. The VM and flash images also
contain target login material. Never commit `.local`, rootfs, images or logs.

The QCOW overlay refers to its downloaded base image by absolute path. Don't
move it casually; fresh clones generate a new overlay. The current target's
Internet/SSH depends on the Mac VM until standalone Ethernet/Wi-Fi is set up.
After disconnecting target workflows, shut down the guest cleanly using
`bash scripts/flash-vm-ssh.sh 'sudo poweroff'`; QEMU should exit. Avoid killing
it during flash or package operations. No background HTTP server is required
by this runbook.

- `Swift.__SharedStringStorage` / fork crash: remove `-daemonize`; use sudo
  foreground Terminal. The launcher rejects this known-bad option.
- `libusb_detach_kernel_driver ... ACCESS`: QEMU needs root and macOS accessory
  permission. Don't disable system security protections.
- Repeating `libusb_kernel_driver_active -5 [NOT_FOUND]`: observed even during
  successful SSH/flash. Check guest `lsusb`, USB interface and SSH before
  deciding it failed; suppressing logs does not fix a connection.
- No USB Ethernet: install the running kernel's `linux-modules-extra`, load
  `rndis_host`/`cdc_ether`, confirm EHCI + `guest-reset=false`.
- `BootRom is not running`: physically re-enter fresh recovery, skip UID probes.
- No APX: verify the small J14 header, power, data cable and USB port. A lit LED
  alone is not proof of recovery.

See [exact run history](xavier-nx-qemu.md) and [Pit Droid handoff](pit-droid-vision-handoff.md).
Offline package checks: `python3 -m unittest discover -s tests -v` and
`bash -n scripts/*.sh` (or loop over scripts if your shell only checks one).

Primary references: [NVIDIA R35.6.4 flashing guide](https://docs.nvidia.com/jetson/archives/r35.6.4/DeveloperGuide/SD/FlashingSupport.html),
[Canonical pinned checksums](https://cloud-images.ubuntu.com/releases/focal/release-20250624/SHA256SUMS),
[QEMU USB](https://www.qemu.org/docs/master/system/devices/usb.html).
