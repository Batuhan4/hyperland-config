#!/usr/bin/env bash
if ! locked_state="$(busctl --user get-property org.freedesktop.secrets \
    /org/freedesktop/secrets/collection/login \
    org.freedesktop.Secret.Collection Locked 2>/dev/null)"; then
    echo 'Keyring status unavailable' >&2
    exit 1
fi
if [[ "${locked_state}" == "b false" ]]; then
    echo 'Keyring is unlocked' >&2
    exit 0
else
    echo 'Keyring is locked' >&2
    exit 1
fi
