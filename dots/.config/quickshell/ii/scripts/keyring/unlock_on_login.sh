#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Wait briefly for the user bus/session services during startup.
for _ in $(seq 1 20); do
    if busctl --user list >/dev/null 2>&1; then
        break
    fi
    sleep 0.2
done

# Skip when already unlocked (e.g. password login with PAM keyring handoff).
if "${SCRIPT_DIR}/is_unlocked.sh" >/dev/null 2>&1; then
    exit 0
fi

# Try blank keyring password first (for auto-unlock setups).
if UNLOCK_PASSWORD='' "${SCRIPT_DIR}/unlock.sh" >/dev/null 2>&1; then
    exit 0
fi

# Best-effort prompt. Cancel means "do nothing".
if command -v kdialog >/dev/null 2>&1; then
    UNLOCK_PASSWORD="$(kdialog --title 'Unlock Login Keyring' --password 'Login password:' 2>/dev/null || true)"
elif command -v systemd-ask-password >/dev/null 2>&1; then
    UNLOCK_PASSWORD="$(systemd-ask-password 'Login password (for keyring unlock):' 2>/dev/null || true)"
else
    exit 0
fi

[[ -n "${UNLOCK_PASSWORD:-}" ]] || exit 0

UNLOCK_PASSWORD="${UNLOCK_PASSWORD}" "${SCRIPT_DIR}/unlock.sh" >/dev/null 2>&1 || true
