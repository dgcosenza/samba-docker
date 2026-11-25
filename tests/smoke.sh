#!/usr/bin/env bash
# Smoke test for dgcosenza/samba image
# Verifies: env-driven share + user provisioning, healthy status, SMB3 auth & file R/W,
# 0600 smbpasswd permissions, env secret scrubbing, read-only smb.conf mount, and negative test.

set -euo pipefail

IMAGE="${1:-dgcosenza/samba:ci-candidate}"
CONTAINER_NAME="samba-smoke-$$"
RO_CONTAINER_NAME="samba-smoke-ro-$$"
TMP_SHARE="$(mktemp -d)"
TMP_CONF="$(mktemp)"

PASS="$(openssl rand -hex 16)"

cleanup() {
    docker rm -f "${CONTAINER_NAME}" "${RO_CONTAINER_NAME}" >/dev/null 2>&1 || true
    rm -rf "${TMP_SHARE}" "${TMP_CONF}"
}
trap cleanup EXIT

chmod 777 "${TMP_SHARE}"

echo "=== Smoke testing ${IMAGE} (env-driven mode) ==="
docker run -d --name "${CONTAINER_NAME}" \
    --security-opt no-new-privileges:true \
    -e FAIL_FAST=1 \
    -e NETBIOS_DISABLE=1 \
    -e AVAHI_DISABLE=1 \
    -e WSDD2_DISABLE=1 \
    -e SAMBA_CONF_MAP_TO_GUEST=Never \
    -e ACCOUNT_testuser="${PASS}" \
    -e UID_testuser=1000 \
    -e SAMBA_VOLUME_CONFIG_demo="[demo]; path = /shares/demo; valid users = testuser; guest ok = no; read only = no; browseable = yes" \
    -v "${TMP_SHARE}:/shares/demo" \
    "${IMAGE}"

echo "Waiting for container healthcheck..."
for i in $(seq 1 30); do
    STATUS="$(docker inspect --format '{{.State.Health.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo "missing")"
    if [ "${STATUS}" = "healthy" ]; then
        echo "OK: Container status is healthy"
        break
    fi
    if [ "${STATUS}" = "missing" ] || [ "$(docker inspect --format '{{.State.Running}}' "${CONTAINER_NAME}" 2>/dev/null || echo false)" != "true" ]; then
        echo "ERROR: Container exited prematurely"
        docker logs "${CONTAINER_NAME}" || true
        exit 1
    fi
    sleep 2
    if [ "${i}" -eq 30 ]; then
        echo "ERROR: Container did not become healthy within 60s (status=${STATUS})"
        docker logs "${CONTAINER_NAME}" || true
        exit 1
    fi
done

echo "Verifying authenticated SMB share listing and file read/write..."
SHARE_LIST="$(docker exec "${CONTAINER_NAME}" smbclient -L 127.0.0.1 -U "testuser%${PASS}")"
printf '%s\n' "${SHARE_LIST}" | grep -qw "demo"
docker exec "${CONTAINER_NAME}" sh -c "printf 'hello-smb\n' > /tmp/probe.txt && smbclient //127.0.0.1/demo -U 'testuser%${PASS}' -c 'put /tmp/probe.txt probe.txt; get probe.txt /tmp/probe-out.txt' && grep -qx 'hello-smb' /tmp/probe-out.txt"
echo "OK: Authenticated SMB read/write succeeded"

echo "Verifying smbpasswd permissions (must be 600)..."
for pwf in /etc/samba/smbpasswd /var/lib/samba/private/smbpasswd; do
    if docker exec "${CONTAINER_NAME}" test -f "${pwf}"; then
        SMBPASS_PERMS="$(docker exec "${CONTAINER_NAME}" stat -c '%a' "${pwf}")"
        if [ "${SMBPASS_PERMS}" != "600" ]; then
            echo "ERROR: ${pwf} mode is ${SMBPASS_PERMS}, expected 600"
            exit 1
        fi
        echo "OK: ${pwf} mode is 600"
    fi
done

echo "Verifying ACCOUNT_testuser was scrubbed from smbd process environment..."
if docker exec "${CONTAINER_NAME}" sh -c 'tr "\0" "\n" < /proc/$(pgrep -o smbd)/environ | grep -q "^ACCOUNT_testuser="'; then
    echo "ERROR: ACCOUNT_testuser still present in smbd environment"
    exit 1
fi
echo "OK: Account secret scrubbed from smbd environment"

echo "Verifying read-only mounted /etc/samba/smb.conf mode..."
cat > "${TMP_CONF}" <<'CONF'
[global]
   workgroup = WORKGROUP
   security = user
   passdb backend = smbpasswd
   map to guest = Never
   disable netbios = yes
   load printers = no
   printcap name = /dev/null

[rotest]
   path = /shares/demo
   valid users = testuser
   guest ok = no
   read only = yes
   browseable = yes
CONF
chmod 644 "${TMP_CONF}"

docker run -d --name "${RO_CONTAINER_NAME}" \
    --security-opt no-new-privileges:true \
    -e FAIL_FAST=1 \
    -e NETBIOS_DISABLE=1 \
    -e AVAHI_DISABLE=1 \
    -e WSDD2_DISABLE=1 \
    -e ACCOUNT_testuser="${PASS}" \
    -e UID_testuser=1000 \
    -v "${TMP_CONF}:/etc/samba/smb.conf:ro" \
    -v "${TMP_SHARE}:/shares/demo:ro" \
    "${IMAGE}"

for i in $(seq 1 20); do
    if docker exec "${RO_CONTAINER_NAME}" smbclient -L 127.0.0.1 -U "testuser%${PASS}" 2>/dev/null | grep -qw "rotest"; then
        echo "OK: Read-only mounted /etc/samba/smb.conf mode verified"
        break
    fi
    sleep 2
    if [ "${i}" -eq 20 ]; then
        echo "ERROR: Read-only smb.conf container failed to serve rotest share"
        docker logs "${RO_CONTAINER_NAME}" || true
        exit 1
    fi
done

echo "Running negative healthcheck test (stopped smbd)..."
if docker run --rm --entrypoint smbclient "${IMAGE}" -L 127.0.0.1 -N >/dev/null 2>&1; then
    echo "ERROR: Healthcheck unexpectedly passed without smbd running"
    exit 1
fi
echo "OK: Negative healthcheck failed as expected"

echo "=== All smoke tests passed for ${IMAGE} ==="
