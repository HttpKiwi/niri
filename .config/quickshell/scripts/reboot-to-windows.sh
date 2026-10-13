#!/usr/bin/env bash
# Reboot into Windows via UEFI BootNext (skips GRUB — works with timeout=0 / hidden).
set -euo pipefail

entry="${WINDOWS_EFI_BOOT:-}"
if [[ -z "${entry}" ]]; then
    # `|| true`: under set -e a failing efibootmgr would exit before the error below
    entry="$( { efibootmgr 2>/dev/null || true; } | sed -n 's/^Boot\([0-9A-Fa-f]*\)[* ]*Windows Boot Manager.*/\1/p' | head -n1)"
fi

if [[ -z "${entry}" ]]; then
    echo "reboot-to-windows: Windows Boot Manager not found in efibootmgr" >&2
    exit 1
fi

# BootNext requires root; systemctl reboot as the calling user is fine
pkexec /usr/bin/efibootmgr -n "${entry}"
exec systemctl reboot
