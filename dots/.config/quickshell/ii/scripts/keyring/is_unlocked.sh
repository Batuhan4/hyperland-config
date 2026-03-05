#!/usr/bin/env bash

collection_from_alias() {
    gdbus call --session \
        --dest org.freedesktop.secrets \
        --object-path /org/freedesktop/secrets \
        --method org.freedesktop.Secret.Service.ReadAlias "$1" 2>/dev/null \
        | sed -n "s/.*objectpath '\\([^']*\\)'.*/\\1/p"
}

collection_path="$(collection_from_alias login)"
if [[ -z "${collection_path}" || "${collection_path}" == "/" ]]; then
    collection_path="$(collection_from_alias default)"
fi

if [[ -z "${collection_path}" || "${collection_path}" == "/" ]]; then
    echo 'Keyring collection not found' >&2
    exit 1
fi

if ! locked_state="$(busctl --user get-property org.freedesktop.secrets \
    "${collection_path}" \
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
