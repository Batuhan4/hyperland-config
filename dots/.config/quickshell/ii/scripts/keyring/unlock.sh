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

# Unlock through Secret Service directly (works for both blank and non-blank keyring passwords).
UNLOCK_PASSWORD="${UNLOCK_PASSWORD}" /usr/bin/python3 - <<'PY'
import os
import sys
import dbus

password = os.environ.get("UNLOCK_PASSWORD", "")

bus = dbus.SessionBus()
obj = bus.get_object("org.freedesktop.secrets", "/org/freedesktop/secrets")
svc = dbus.Interface(obj, "org.freedesktop.Secret.Service")
internal = dbus.Interface(obj, "org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface")

collection = svc.ReadAlias("login")
if collection == "/":
    collection = svc.ReadAlias("default")
if collection == "/":
    sys.exit(1)

_, session = svc.OpenSession("plain", dbus.String(""))
secret = dbus.Struct((
    dbus.ObjectPath(session),
    dbus.ByteArray(b""),
    dbus.ByteArray(password.encode("utf-8")),
    dbus.String("text/plain"),
))

internal.UnlockWithMasterPassword(dbus.ObjectPath(collection), secret)
PY

unset UNLOCK_PASSWORD
echo '' >&2
