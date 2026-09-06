# Xavier NX flashing host on Apple Silicon

This is the current bring-up path for the owner's **Xavier NX Developer Kit**.
The Orin ISO instructions elsewhere in this repository are historical and do
not apply to this board.

## Current result

QSPI and NVMe flashing completed successfully. The installed Jetson accepts
key-based SSH as `xerogrid`, reports hostname `xavier-nx`, kernel
`5.10.216-tegra` / L4T R35.6.4, and mounts `/dev/nvme0n1p1` as its ext4 root.
No systemd services were failed. DNS and HTTPS to GitHub (HTTP 200) work through
the Mac's dedicated VM. `nvgpu` and `uvcvideo` are loaded; video0–video3 identify
as Logitech BRIO. No video capture or motion commands have been performed.

The APP partition was expanded using Ubuntu's `growpart`, after a dry run and
guards for root device, exact serial (space-trimmed) and disk capacity.
`resize2fs` completed online: 976470540 4 KiB blocks; `df -h /` reports 3.6 TiB.
The ext4 reserved space was set to 1%. A clean reboot verification passed:
the same key authenticated, root remained on NVMe at 3.6 TiB, no services were
failed, and HTTPS to GitHub again returned HTTP 200. `sfdisk --verify` reported
no partition-table errors. The microSD filesystem UUIDs match the pre-flash
readings; its normal-boot name is `/dev/mmcblk0` (recovery used `mmcblk1`).

Private keys and the generated login password are stored with mode 600 under
the Git-ignored `.local/jetson-vm/` directory. They have not been committed or
uploaded. Target SSH host keys are pinned in `xavier-known-hosts` there.

Keep the administrator VM's Terminal open for the current USB connection.
After a Jetson/VM restart, reestablish the VM side of USB networking:

```bash
bash scripts/flash-vm-ssh.sh 'sudo bash -s' < scripts/enable-xavier-usb-internet.sh
bash scripts/xavier-ssh.sh
```

This internet path depends on the Mac and VM; standalone Wi-Fi/Ethernet is not
configured yet. The target's USB bridge provides the default route through
`192.168.55.100`; VM NAT forwards only the `192.168.55.0/24` subnet.

The prior NVMe EFI/exFAT `BC4` layout was overwritten with explicit owner
authorization. There is no backup of that old volume from this session.
The microSD was excluded from the flash indices.

## Bring-up history

- DARKSTAR is an Apple Silicon Mac running macOS 27.
- NVIDIA APX `0955:7e19` appears after the correct **J14 9–10** recovery sequence.
  J14 is the small button header under the module, not the 40-pin GPIO header.
- Homebrew QEMU 11.1.1 runs the official Ubuntu 20.04 **amd64** cloud image.
- The Ubuntu image matches Canonical's downloaded SHA256SUMS.
- The guest sees `0955:7e19`; NVIDIA `tegrarcm_v2 --chip 0x19 0 --uid`
  successfully read the chip ID once. A subsequent standalone UID read after
  reattachment failed; a fresh recovery session is required before proceeding.
- NVIDIA Jetson Linux **35.6.4 / JetPack 5.1.6** BSP and sample root filesystem
  were downloaded from NVIDIA and decompressed successfully.
- `apply_binaries.sh` completed successfully. Headless configuration completed
  and was verified: release r35.6.4, hostname `xavier-nx`, SSH enabled and the
  `xerogrid` authorized key present.
- The first `--initrd --network usb0` RAM-boot test stalled at
  `BootRom is not running`, followed by an `--isapplet` probe. No recovery
  reconnect had occurred after the earlier standalone UID test. The attempt
  was stopped; retry after a physical recovery power cycle.
- Installed `python-is-python3` after finding that `flash.sh` expects `python`
  when calculating its version-file CRC. Regenerate the recovery boot package
  on the next attempt to include that correction.
- The next recovery package regeneration completed with the Python fix. However,
  the physical recovery power cycle did not produce a new APX device: neither
  macOS nor Linux saw it, and the command exited with `No devices to flash`.
- The VM was cleanly restarted with a USB 2 EHCI controller and
  `guest-reset=false`, replacing XHCI, to test more reliable recovery handling.
  After a fresh physical recovery cycle, the BootROM handshake, BCT transfers,
  complete 58 MB blob upload and `RCM-boot started` all succeeded. The target
  reappeared as `0955:7035`, **Linux for Tegra**, serial `1654621008678`.
- Recovery networking is not yet connected: QEMU reported
  `libusb_detach_kernel_driver: -3 [ACCESS]` and the guest reported
  `can't set config #1, error -32`. The cloud guest also lacked USB network
  modules; `linux-modules-extra-5.4.0-216-generic` was installed, and
  `cdc_ether`, `rndis_host`, and `usbnet` successfully loaded.
  macOS USB driver capture requires root privileges for this command-line host.
- The unprivileged VM was shut down cleanly after the package update completed.
  An administrator-authorized restart is needed to validate USB networking.
- Administrator launch from Terminal with `-daemonize` crashed in the macOS
  Objective-C runtime (`Swift.__SharedStringStorage initialize` during `fork`).
  Use foreground launch without that flag and keep Terminal open. The launcher
  now rejects `-daemonize` to prevent repeating this known failure.
- Foreground administrator launch succeeded. The VM bound the Jetson USB
  interface using `rndis_host` as `eth0`; target SSH at `fe80::1%eth0` worked
  after bringing up the link. Repeated `libusb_kernel_driver_active -5`
  messages did not prevent this verified connection.
- Target-reported model: NVIDIA Jetson Xavier NX Developer Kit. Bootloader
  device-tree IDs: `3668-0000-300`; part string `699-13668-0000-300 E.0`.
- Target NVMe: `/dev/nvme0n1`, Crucial `CT4000P3SSD8`, serial `2320E6D72855`,
  **4,000,787,030,016 bytes**, **7,814,037,168 sectors of 512 bytes**.
  Existing EFI and exFAT `BC4` partitions were identified without mounting.
  The owner explicitly authorized wiping/formatting this NVMe after this check.
  The microSD is `/dev/mmcblk1` (7,988,051,968 bytes) and is not a flash target.
- Caution: the recovery `/sbin/reboot` is a generated shell wrapper that ignores
  arguments and runs `busybox reboot -f`. Even `reboot --help` reboots the board.
  A help probe unintentionally rebooted this session; physical recovery was
  requested again while offline image preparation continued.
- QSPI-only image generation completed with the measured board identifiers
  and NVMe boot-order overlay. `scripts/prepare-xavier-nvme.sh` performs the
  subsequent external-only append phase using the measured sector count and
  an initial 32 GiB APP image, to be expanded after installation.
- NVMe system image generation completed, including filesystem packaging;
  the tool is finishing the final recovery boot package. The generated external
  XML correctly records `7814037168` 512-byte sectors. However, the NVIDIA
  partition generator placed the backup GPT at byte `2199023238144` (2 TiB
  boundary), not the actual end of the drive. The supplied target flash script
  detects an undersized GPT and asks `parted` to fix it. Verify the resulting
  GPT and expand APP/filesystem to the full drive after installation.
- The complete package generated successfully. The guarded flash launcher
  accepted only QSPI (`3:0`) and external NVMe (`9:0`) index entries, and the
  flash completed successfully. The NVMe's old partitions were replaced; APP was
  formatted ext4 and the system archive transferred. QSPI erase and firmware
  writes/checksums completed. The target flash script fixed
  the undersized GPT and reports the full 4001 GB physical disk.
  No microSD writes were included in the accepted package. The successful log
  in the VM is `Linux_for_Tegra/initrdlog/flash_1-1_0_20260906-154825.log`.

## Local environment

All VM disks, downloads, private keys and generated credentials are under
`.local/jetson-vm/`, which is ignored by Git. The guest disk is a 160 GiB sparse
QCOW2 overlay; it does not map a Mac physical disk.

```bash
bash scripts/start-flash-vm.sh
bash scripts/flash-vm-ssh.sh 'lsusb'
python3 scripts/flash-vm-qmp.py '{"execute":"query-status"}'
```

Do not start a second copy while the VM is running. SSH listens only on
`127.0.0.1:22222`. The preparation HTTP server listens only on
`127.0.0.1:18080`, serving the downloads directory; its guest-side address is
`10.0.2.2:18080`. USB passthrough matches NVIDIA's vendor ID so the same board
can reconnect with a different product ID after boot. Keep other NVIDIA USB
devices disconnected during this workflow.

For administrator launch, run `sudo bash scripts/start-flash-vm.sh` in Terminal
and leave it open. Do not use QEMU's `-daemonize` on this host. The QMP socket,
PID file and serial log can be assigned back to the
owner after launch; the VM must retain privileges to capture the USB gadget.
Administrator credentials belong only in the macOS authorization dialog, never
in scripts or chat. Starting this VM does not automatically run a flash command.

The BSP directory in the guest is `/home/flash/jetson/Linux_for_Tegra`.
`scripts/configure-xavier-rootfs.sh` configures the staged filesystem after
`apply_binaries.sh` succeeds: user `xerogrid`, hostname `xavier-nx`, SSH public
key, and America/New_York timezone. The generated password and private key
remain in the ignored local VM directory.

## Flash workflow used

1. Physically re-enter recovery on J14. Do not consume the new session with
   another standalone `tegrarcm_v2 --uid` test.
2. Boot the target with `l4t_initrd_flash.sh --initrd --network usb0` to inspect
   the NVMe model and exact capacity without installing to it.
3. Prepare QSPI and external images using **Workflow 11, Example 2** in the BSP's
   `tools/kernel_flash/README_initrd_flash.txt`. That workflow explicitly
   supports Xavier NX developer modules booting NVMe without an SD card.
4. Set the external partition layout from the verified NVMe capacity; use a
   manageable initial root filesystem image and expand it on the target.
5. Flash, boot, verify SSH, root filesystem on NVMe, capacity and NVIDIA drivers.

Do not use Orin board names or `flash_t234_qspi.xml` for this Xavier.
Recovery USB upload, Linux USB networking, target SSH and storage flashing
through this QEMU setup have now all been verified.

## Sources

- [NVIDIA JetPack 5.1.6](https://developer.nvidia.com/embedded/jetpack-sdk-516)
- [NVIDIA Jetson Linux 35.6.4 downloads](https://developer.nvidia.com/embedded/jetson-linux-r3564)
- [NVIDIA flashing guide](https://docs.nvidia.com/jetson/archives/r35.6.4/DeveloperGuide/SD/FlashingSupport.html)
- [Canonical Ubuntu 20.04 cloud image](https://cloud-images.ubuntu.com/releases/focal/release/)
- [QEMU USB passthrough](https://www.qemu.org/docs/master/system/devices/usb.html)
- [libusb macOS driver capture requirements](https://github.com/libusb/libusb/wiki/FAQ)
- [QEMU macOS daemonization crash report](https://gitlab.com/qemu-project/qemu/-/issues/2515)
