#!/usr/bin/env bash
# Based on https://unix.stackexchange.com/a/602935

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Skip if already unlocked
if "${SCRIPT_DIR}/is_unlocked.sh"; then
    exit 1
fi

# Prompt only when UNLOCK_PASSWORD is truly unset.
# If it's set to an empty string, treat that as an intentional blank keyring password.
if [[ -z "${UNLOCK_PASSWORD+x}" ]]; then
    if [[ -t 0 ]]; then
        echo -n 'Login password: ' >&2
        read -r -s UNLOCK_PASSWORD || exit 1
    elif command -v kdialog >/dev/null 2>&1; then
        UNLOCK_PASSWORD="$(kdialog --title 'Unlock Login Keyring' --password 'Login password:' 2>/dev/null || true)"
    elif command -v systemd-ask-password >/dev/null 2>&1; then
        UNLOCK_PASSWORD="$(systemd-ask-password 'Login password (for keyring unlock):' 2>/dev/null || true)"
    else
        exit 1
    fi
fi

[[ "${UNLOCK_PASSWORD+x}" == "x" ]] || exit 1

# Unlock
killall -q -u "$(whoami)" gnome-keyring-daemon
eval $(echo -n "${UNLOCK_PASSWORD}" \
           | gnome-keyring-daemon --daemonize --login \
           | sed -e 's/^/export /')
unset UNLOCK_PASSWORD
echo '' >&2
