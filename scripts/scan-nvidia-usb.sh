#!/usr/bin/env bash
# List USB devices that look like NVIDIA Jetson recovery (APX) on macOS.
set -euo pipefail

python3 - <<'PY'
import re, subprocess

out = subprocess.check_output(["ioreg", "-p", "IOUSB", "-l", "-w", "0"], text=True, errors="replace")
blocks = re.split(r"\n\s*\+-o ", out)
found = []
for b in blocks:
    name = b.split("<", 1)[0].strip()
    vend = re.search(r'"USB Vendor Name" = "([^"]+)"', b)
    prod = re.search(r'"USB Product Name" = "([^"]+)"', b)
    idv = re.search(r'"idVendor" = (\d+)', b)
    idp = re.search(r'"idProduct" = (\d+)', b)
    if not idv:
        continue
    vid = int(idv.group(1))
    pid = int(idp.group(1)) if idp else 0
    vname = vend.group(1) if vend else "?"
    pname = prod.group(1) if prod else name
    blob = f"{vname} {pname}".lower()
    if vid == 0x0955 or "nvidia" in blob or "apx" in blob or "tegra" in blob:
        found.append(f"{vname} | {pname} | {vid:04x}:{pid:04x}")

print("NVIDIA-like USB devices:")
if found:
    print("\n".join(found))
else:
    print("(none)")
    print("Expected recovery: idVendor 0955, product 7523/7623/7323/7423 (Orin) or 7e19 (Xavier NX).")
PY
