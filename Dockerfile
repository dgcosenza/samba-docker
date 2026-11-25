# syntax=docker/dockerfile:1.7
# Hardened Samba (SMB3) File Server on Debian 13 (trixie)
# Upstream: https://www.samba.org/ (Debian 13 official packages)
# Env-driven config parity inspired by ServerContainers/samba
# Maintainer: Daniel G. Cosenza from FNX Labs

ARG DEBIAN_BASE=debian:trixie-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0
ARG SAMBA_VERSION=4.22
ARG IMAGE_CREATED=1970-01-01T00:00:00Z
ARG IMAGE_REVISION=dev
ARG IMAGE_SOURCE=https://github.com/dgcosenza/samba-docker

FROM ${DEBIAN_BASE} AS runtime

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG SAMBA_VERSION
ARG IMAGE_CREATED
ARG IMAGE_REVISION
ARG IMAGE_SOURCE
ARG DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.title="Samba File Server on Debian 13 (trixie)" \
      org.opencontainers.image.description="Hardened SMB3 Samba file server on Debian 13 (trixie-slim) with env-driven share/user provisioning, read-only smb.conf support, and daily CVE-gated builds, maintained by Daniel G. Cosenza from FNX Labs." \
      org.opencontainers.image.version="${SAMBA_VERSION}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.url="https://hub.docker.com/r/dgcosenza/samba" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="${IMAGE_SOURCE}#readme" \
      org.opencontainers.image.vendor="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.authors="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.licenses="GPL-3.0-or-later AND MIT" \
      org.opencontainers.image.base.name="debian:trixie-slim" \
      io.github.dgcosenza.samba.version="${SAMBA_VERSION}"

RUN set -eux; \
    apt-get update; \
    apt-get -y upgrade; \
    apt-get install -y --no-install-recommends \
        avahi-daemon \
        ca-certificates \
        procps \
        samba \
        samba-common-bin \
        smbclient \
        tini \
        tzdata \
        wsdd2; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
    \
    # Configure Avahi to run without D-Bus inside a container \
    sed -i 's/^#*enable-dbus=.*/enable-dbus=no/' /etc/avahi/avahi-daemon.conf; \
    rm -rf /etc/avahi/services/*; \
    mkdir -p /container/config /container/scripts /shares /run/samba /var/lib/samba/private /var/log/samba /external/avahi; \
    chmod 0700 /var/lib/samba/private; \
    touch /external/avahi/not-mounted; \
    smbd --version; \
    smbclient --version

COPY --chmod=0644 config/smb.conf.default /container/config/smb.conf.default
COPY --chmod=0644 config/samba.service /container/config/samba.service
COPY --chmod=0755 scripts/entrypoint.sh /container/scripts/entrypoint.sh
COPY --chmod=0755 scripts/samba_create_user_dir.sh /container/scripts/samba_create_user_dir.sh

ENV PATH="/container/scripts:${PATH}" \
    TZ=UTC

VOLUME ["/shares"]

EXPOSE 137/udp 138/udp 139/tcp 445/tcp

ENTRYPOINT ["/usr/bin/tini", "--", "/container/scripts/entrypoint.sh"]
CMD ["smbd", "--foreground", "--no-process-group", "--debug-stdout"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD ["sh", "-c", "smbclient -L 127.0.0.1 -N >/dev/null 2>&1"]
