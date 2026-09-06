# Package validation — 2026-09-06

Post-show packaging audit: the owner reported the subsequent Pit Droid live
vision/motion test ran great. The completed deployment and acceptance guides
are linked from [the project handoff](pit-droid-vision-handoff.md). This does not
change the second-Mac validation limitation below. No new flash or hardware
control was performed during the documentation/package audit.

- All three cached download SHA-256 hashes match `config/downloads.json`.
- Offline unit tests cover cloud-init key-only access, generated artifact
  permissions in a mocked fresh setup, existing-VM refusal, valid/invalid
  target profiles, capacity bounds, shell syntax, and daemonization refusal.
- `git diff --check` passes. Private files remain Git-ignored and excluded
  from the source commit.
- The underlying workflow was verified on DARKSTAR with a Xavier NX and
  4 TB Crucial NVMe: successful QSPI/NVMe flash, expansion, clean reboot,
  saved-key SSH, NVIDIA GPU driver, Brio enumeration, DNS and HTTPS.
- The portable initializer and newly guarded wrappers were reviewed/tested
  offline. They have **not** been used to reflash the working target, and a
  clean second-Mac end-to-end test remains outstanding. Mocks do not establish
  real QEMU, cloud-init, package-server or USB compatibility on another Mac.

Run: `python3 -m unittest discover -s tests -v` and
`python3 scripts/setup-flash-vm.py --verify-downloads`.
