#!/usr/bin/env bash
# Sourced by guest preparation/flash scripts. Never infer another board's identity.
source "${TARGET_PROFILE:-/home/flash/target.env}" || exit 1
invalid_profile() { echo 'Invalid/incomplete target profile; repeat RAM-only identity inspection.' >&2; exit 1; }
[[ "${BOARDID:-}" == 3668 && "${BOARDSKU:-}" == 0000 ]] || {
  echo 'Only Xavier NX P3668-0000 developer modules are supported here.' >&2; exit 1;
}
[[ "${FAB:-}" =~ ^[A-Za-z0-9]+$ && "$FAB" != REPLACE* ]] || invalid_profile
[[ "${BOARDREV:-}" =~ ^[A-Za-z0-9.]+$ && "$BOARDREV" != REPLACE* ]] || invalid_profile
[[ "${EXPECTED_NVME_SERIAL:-}" =~ ^[A-Za-z0-9._-]+$ && "$EXPECTED_NVME_SERIAL" != REPLACE* ]] || invalid_profile
[[ "${EXT_NUM_SECTORS:-}" =~ ^[0-9]{1,12}$ && ${EXT_NUM_SECTORS:0:1} != 0 ]] || invalid_profile
[[ "${APP_SIZE_GIB:-}" =~ ^[0-9]{1,3}$ && ${APP_SIZE_GIB:0:1} != 0 ]] || invalid_profile
(( APP_SIZE_GIB >= 16 && APP_SIZE_GIB <= 64 )) || invalid_profile
(( EXT_NUM_SECTORS * 512 > (APP_SIZE_GIB + 2) * 1024 * 1024 * 1024 )) || invalid_profile
export BOARDID BOARDSKU FAB BOARDREV EXT_NUM_SECTORS APP_SIZE_GIB EXPECTED_NVME_SERIAL
export FUSELEVEL=fuselevel_production ADDITIONAL_DTB_OVERLAY_OPT=BootOrderNvme.dtbo
