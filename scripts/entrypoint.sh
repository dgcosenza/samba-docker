#!/usr/bin/env bash
# Entrypoint for dgcosenza/samba on Debian 13 (trixie)
# Supports both mounted read-only /etc/samba/smb.conf and env-driven config
# (GROUP_*, ACCOUNT_*, UID_*, GROUPS_*, SAMBA_CONF_*, SAMBA_GLOBAL_*, SAMBA_VOLUME_CONFIG_*).

set -eo pipefail

if [ -n "${FAIL_FAST:-}" ]; then
    set -u
fi

mkdir -p /run/samba /var/lib/samba/private /var/log/samba /var/cache/samba /etc/avahi/services
chmod 0700 /var/lib/samba/private

# Detect if /etc/samba/smb.conf is externally mounted read-only (or non-writable)
SMB_CONF="/etc/samba/smb.conf"
CUSTOM_SMB_CONF=0
if [ -f "${SMB_CONF}" ] && [ ! -w "${SMB_CONF}" ]; then
    CUSTOM_SMB_CONF=1
    echo ">> SAMBA: Detected read-only mounted ${SMB_CONF}; preserving user configuration."
fi

if [ "${CUSTOM_SMB_CONF}" -eq 0 ]; then
    cp /container/config/smb.conf.default "${SMB_CONF}"

    if [ -n "${DISABLE_FRUIT_DEFAULTS:-}" ]; then
        sed -i -E '/fruit:|vfs objects|ea support/d' "${SMB_CONF}"
    fi

    if [ -n "${SAMBA_CONF_SERVER_ROLE:-}" ]; then
        sed -i "s|standalone server|${SAMBA_CONF_SERVER_ROLE}|g" "${SMB_CONF}"
    fi

    echo "   log level = ${SAMBA_CONF_LOG_LEVEL:-1}" >> "${SMB_CONF}"
    echo "   workgroup = ${SAMBA_CONF_WORKGROUP:-WORKGROUP}" >> "${SMB_CONF}"
    echo "   server string = ${SAMBA_CONF_SERVER_STRING:-Samba Server}" >> "${SMB_CONF}"
    echo "   map to guest = ${SAMBA_CONF_MAP_TO_GUEST:-Bad User}" >> "${SMB_CONF}"

    if [ -n "${NETBIOS_DISABLE:-}" ]; then
        echo "   disable netbios = yes" >> "${SMB_CONF}"
    fi

    if [ -n "${SAMBA_GLOBAL_STANZA:-}" ]; then
        printf '%s\n' "${SAMBA_GLOBAL_STANZA}" | tr ';' '\n' | while IFS= read -r line; do
            trimmed="$(printf '%s' "${line}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            [ -n "${trimmed}" ] && printf '   %s\n' "${trimmed}" >> "${SMB_CONF}"
        done
    fi

    while IFS='=' read -r var val; do
        key="${var#SAMBA_GLOBAL_CONFIG_}"
        key="${key//_SPACE_/ }"
        key="${key//_COLON_/:}"
        printf '   %s = %s\n' "${key}" "${val}" >> "${SMB_CONF}"
    done < <(env | grep '^SAMBA_GLOBAL_CONFIG_' || true)

    MODEL_VAL="${MODEL:-TimeCapsule}"
    sed -i "s|TimeCapsule|${MODEL_VAL}|g" "${SMB_CONF}"
fi

# Configure Avahi service definition
cp /container/config/samba.service /etc/avahi/services/samba.service
MODEL_VAL="${MODEL:-TimeCapsule}"
sed -i '/<\/service-group>/d' /etc/avahi/services/samba.service
cat >> /etc/avahi/services/samba.service <<EOF
 <service>
  <type>_device-info._tcp</type>
  <port>0</port>
  <txt-record>model=${MODEL_VAL}</txt-record>
 </service>
</service-group>
EOF

# Create explicit groups (GROUP_<name>=<gid>)
while IFS='=' read -r var gid; do
    gname="${var#GROUP_}"
    if ! getent group "${gname}" >/dev/null 2>&1; then
        echo ">> GROUP: adding ${gname} (GID ${gid})"
        groupadd -g "${gid}" "${gname}"
    fi
done < <(env | grep '^GROUP_' || true)

# Create user accounts (ACCOUNT_<name>=<password-or-smbpasswd-hash>, UID_<name>=<uid>)
ACCOUNT_VARS=()
while IFS= read -r var; do
    [ -n "${var}" ] && ACCOUNT_VARS+=("${var}")
done < <(compgen -v ACCOUNT_ || true)

for var in "${ACCOUNT_VARS[@]}"; do
    raw_name="${var#ACCOUNT_}"
    account_name="$(printf '%s' "${raw_name}" | tr '[:upper:]' '[:lower:]')"
    account_pass="${!var}"

    uid_var="UID_${raw_name}"
    uid_var_lower="UID_${account_name}"
    account_uid="${!uid_var:-${!uid_var_lower:-}}"

    if ! id "${account_name}" >/dev/null 2>&1; then
        if [[ "${account_uid}" =~ ^[0-9]+$ ]] && [ "${account_uid}" -gt 0 ]; then
            echo ">> ACCOUNT: adding ${account_name} (UID/GID ${account_uid})"
            if ! getent group "${account_name}" >/dev/null 2>&1; then
                if ! getent group "${account_uid}" >/dev/null 2>&1; then
                    groupadd -g "${account_uid}" "${account_name}"
                else
                    groupadd "${account_name}"
                fi
            fi
            useradd --no-create-home --uid "${account_uid}" --gid "${account_name}" --shell /usr/sbin/nologin "${account_name}"
        else
            echo ">> ACCOUNT: adding ${account_name}"
            useradd --no-create-home --shell /usr/sbin/nologin "${account_name}"
        fi
    fi

    # Provision Samba password (supports both smbpasswd hash lines and plaintext passwords)
    if printf '%s' "${account_pass}" | grep -qE "^${account_name}:[0-9]+:.*:$"; then
        echo ">> ACCOUNT: loading pre-hashed SMB credentials for ${account_name}"
        smbpasswd -a -n "${account_name}" >/dev/null
        clean_hash="$(printf '%s' "${account_pass}" | sed 's/^[^:]*:[0-9]*://')"
        if [ -f /var/lib/samba/private/smbpasswd ]; then
            sed -i "s|^\(${account_name}:[0-9]*:\).*|\1${clean_hash}|" /var/lib/samba/private/smbpasswd
        fi
    else
        printf '%s\n%s\n' "${account_pass}" "${account_pass}" | smbpasswd -s -a "${account_name}" >/dev/null
    fi
    smbpasswd -e "${account_name}" >/dev/null

    groups_var="GROUPS_${raw_name}"
    groups_var_lower="GROUPS_${account_name}"
    account_groups="${!groups_var:-${!groups_var_lower:-}}"
    if [ -n "${account_groups}" ]; then
        IFS=',' read -ra grp_list <<< "${account_groups}"
        for grp in "${grp_list[@]}"; do
            [ -n "${grp}" ] && usermod -aG "${grp}" "${account_name}"
        done
    fi

    # Scrub credential from runtime process environment
    unset "${var}"
done

# Harden Samba password database permissions (avoid 0644 warning on smbpasswd)
chmod 0700 /var/lib/samba/private
for dbfile in /var/lib/samba/private/smbpasswd /var/lib/samba/private/passdb.tdb /var/lib/samba/private/secrets.tdb; do
    [ -f "${dbfile}" ] && chmod 0600 "${dbfile}"
done

# Append SAMBA_VOLUME_CONFIG_* sections when smb.conf is container-managed
if [ "${CUSTOM_SMB_CONF}" -eq 0 ]; then
    echo "" >> "${SMB_CONF}"
    while IFS= read -r var; do
        [ -z "${var}" ] && continue
        val="${!var}"
        printf '%s\n' "${val}" | sed 's/;/\n/g' >> "${SMB_CONF}"
        if printf '%s\n' "${val}" | sed 's/;/\n/g' | grep -qiE 'fruit:time machine.*yes'; then
            cat >> "${SMB_CONF}" <<'TM'
   durable handles = yes
   kernel oplocks = no
   kernel share modes = no
   posix locking = no
   inherit acls = yes
TM
        fi
        vol_path="$(printf '%s\n' "${val}" | tr ';' '\n' | awk -F= '/^[[:space:]]*path[[:space:]]*=/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}')"
        if [[ "${vol_path}" == *"%U" ]]; then
            base_dir="${vol_path%/%U}"
            echo "   root preexec = /container/scripts/samba_create_user_dir.sh '${base_dir}' %U" >> "${SMB_CONF}"
        fi
        echo "" >> "${SMB_CONF}"
    done < <(compgen -v SAMBA_VOLUME_CONFIG_ | sort || true)
fi

echo ">> SAMBA: validating configuration with testparm -s"
testparm -s "${SMB_CONF}" >/dev/null

# Start optional companion daemons unless disabled
if [ -z "${NETBIOS_DISABLE:-}" ]; then
    echo ">> SAMBA: starting nmbd"
    nmbd --foreground --no-process-group --debug-stdout &
fi

if [ -z "${WSDD2_DISABLE:-}" ]; then
    echo ">> SAMBA: starting wsdd2"
    wsdd2 &
fi

if [ -z "${AVAHI_DISABLE:-}" ]; then
    if [ ! -f /external/avahi/not-mounted ]; then
        cp /etc/avahi/services/samba.service /external/avahi/samba.service
    else
        echo ">> SAMBA: starting avahi-daemon"
        avahi-daemon --no-drop-root --no-rlimits &
    fi
fi

# Keep backwards compatibility with ServerContainers runsvdir CMD if passed
if [ "${1:-}" = "runsvdir" ]; then
    set -- smbd --foreground --no-process-group --debug-stdout
fi

echo ">> SAMBA: executing $*"
exec "$@"
