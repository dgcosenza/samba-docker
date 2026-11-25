#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${1:?base directory required}"
USER_NAME="${2:?username required}"

TARGET="${BASE_DIR}/${USER_NAME}"
if [ ! -d "${TARGET}" ]; then
    mkdir -p "${TARGET}"
    chown "${USER_NAME}:${USER_NAME}" "${TARGET}" || chown "${USER_NAME}" "${TARGET}"
    chmod 0700 "${TARGET}"
fi
