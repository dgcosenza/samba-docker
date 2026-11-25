# Samba (SMB3) File Server on Debian 13 (trixie)

[![CI](https://github.com/dgcosenza/samba-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/samba-docker/actions/workflows/daily.yml)
[![Docker Hub Pulls](https://img.shields.io/docker/pulls/dgcosenza/samba?label=docker%20pulls)](https://hub.docker.com/r/dgcosenza/samba)
[![Image Size](https://img.shields.io/docker/image-size/dgcosenza/samba/latest?label=image%20size)](https://hub.docker.com/r/dgcosenza/samba)
[![License](https://img.shields.io/github/license/dgcosenza/samba-docker)](LICENSE)

A hardened, continuously rebuilt **Samba (SMB3)** file server container image on **Debian 13 (`trixie-slim`)**, featuring drop-in environment-driven user/share configuration (`ACCOUNT_*`, `UID_*`, `SAMBA_VOLUME_CONFIG_*`), clean read-only mounted `/etc/samba/smb.conf` support, `0600` password database permissions, `tini` PID 1, and functional `smbclient` healthchecks.

Maintained by **Daniel G. Cosenza from FNX Labs**.

## Current Versions

<!-- versions:start -->
_Last verified build: **2026-11-24** (UTC)_

| Component | Resolved Version |
|-----------|------------------|
| Samba | `4.22.11` (`2:4.22.11+dfsg-0+deb13u1`) |
| Base OS | Debian `13` (`debian:trixie-slim`) |
| Fixable Critical/High (Trivy / Grype) | `0` / `0` |

**Recent upstream updates:**
- Initial hardened Debian 13 release for Samba 4.22.x with `wsdd2`, `avahi-daemon`, and `tini`.
<!-- versions:end -->

## Supported Tags

| Tag | Description |
|-----|-------------|
| `latest` | Moving tag tracking the newest verified daily build |
| `<version>` | Latest build for a specific Debian Samba release (e.g. `4.22.11`) |
| `<version>-YYYYMMDD` | Immutable date-stamped build (e.g. `4.22.11-20261124`) |
| `sha-<short>` | Immutable commit-stamped build |

## Quick Start

### Docker CLI

```bash
docker run -d --name samba \
  --security-opt no-new-privileges:true \
  -p 127.0.0.1:445:445 \
  -e NETBIOS_DISABLE=1 \
  -e AVAHI_DISABLE=1 \
  -e WSDD2_DISABLE=1 \
  -e SAMBA_CONF_MAP_TO_GUEST=Never \
  -e ACCOUNT_alice=change_me_password \
  -e UID_alice=1000 \
  -e SAMBA_VOLUME_CONFIG_media="[media]; path = /shares/media; valid users = alice; guest ok = no; read only = no; browseable = yes" \
  -v ./media:/shares/media \
  dgcosenza/samba:latest
```

### Docker Compose

```yaml
services:
  samba:
    image: dgcosenza/samba:latest
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    network_mode: host
    env_file:
      - ./samba.env
    environment:
      TZ: UTC
      FAIL_FAST: "1"
      NETBIOS_DISABLE: "1"
      AVAHI_DISABLE: "1"
      WSDD2_DISABLE: "1"
    volumes:
      - ./smb.conf:/etc/samba/smb.conf:ro
      - ./shares/data:/shares/data
    healthcheck:
      test: ["CMD-SHELL", "smbclient -L 127.0.0.1 -N >/dev/null 2>&1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

See [docker-compose.example.yml](docker-compose.example.yml) for a full example.

## Configuration

### Environment Variables

Drop-in compatible with the `ServerContainers/samba` env-driven scheme:

| Variable | Description | Default |
|----------|-------------|---------|
| `ACCOUNT_<user>` | Create Samba user with plaintext password or pre-hashed `smbpasswd` entry (scrubbed from env before `exec smbd`) | — |
| `UID_<user>` | Numeric UID (and matching primary GID) for `<user>` | Auto |
| `GROUPS_<user>` | Comma-separated supplementary groups for `<user>` | — |
| `GROUP_<name>` | Create group `<name>` with the given GID | — |
| `SAMBA_VOLUME_CONFIG_<id>` | Semicolon- or newline-delimited share stanza (when `/etc/samba/smb.conf` is not mounted `:ro`) | — |
| `SAMBA_CONF_SERVER_ROLE` | Global `server role` | `standalone server` |
| `SAMBA_CONF_WORKGROUP` | Global `workgroup` | `WORKGROUP` |
| `SAMBA_CONF_SERVER_STRING` | Global `server string` | `Samba Server` |
| `SAMBA_CONF_MAP_TO_GUEST` | Global `map to guest` | `Bad User` |
| `SAMBA_CONF_LOG_LEVEL` | Global `log level` | `1` |
| `SAMBA_GLOBAL_STANZA` | Semicolon-separated extra `[global]` directives | — |
| `SAMBA_GLOBAL_CONFIG_<key>` | Individual `[global]` setting (`_SPACE_` -> space, `_COLON_` -> `:`) | — |
| `DISABLE_FRUIT_DEFAULTS` | Strip macOS `vfs_fruit` defaults when set | Unset |
| `MODEL` | macOS / Avahi model identifier (`fruit:model`) | `TimeCapsule` |
| `NETBIOS_DISABLE` | Disable `nmbd` and NetBIOS when set | Unset |
| `AVAHI_DISABLE` | Disable `avahi-daemon` when set | Unset |
| `WSDD2_DISABLE` | Disable `wsdd2` (WS-Discovery) when set | Unset |
| `FAIL_FAST` | Exit immediately on startup configuration errors | Unset |
| `TZ` | Container timezone | `UTC` |

### Volumes & Config Paths

| Path | Purpose |
|------|---------|
| `/shares` | Base mount point for shared host directories |
| `/etc/samba/smb.conf` | Optional read-only custom `smb.conf` mount (when mounted `:ro`, the entrypoint preserves it verbatim while still creating `ACCOUNT_*`/`UID_*`/`GROUP_*` credentials) |

### Ports

- `445/tcp` — SMB2/SMB3 over TCP
- `139/tcp`, `137/udp`, `138/udp` — Optional NetBIOS (disabled when `NETBIOS_DISABLE=1`)

### User, UID, and GID

- `smbd` starts as `root` (required to bind port `445` and switch effective UID/GID per authenticated SMB session and `force user` directive), while remaining compatible with `security_opt: [no-new-privileges:true]`.
- Account passwords are stored in `/var/lib/samba/private/smbpasswd` with strict **`0600`** permissions (inside `0700 /var/lib/samba/private`) and scrubbed from the `smbd` process environment via `unset`.

### Healthcheck

```bash
smbclient -L 127.0.0.1 -N >/dev/null 2>&1
```

Performs a live SMB protocol query against `smbd` rather than merely counting running processes.

## Upgrade and Migration from `ghcr.io/servercontainers/samba`

1. Keep your existing `samba.env` (`ACCOUNT_*`, `UID_*`), volume mounts, and optional `/etc/samba/smb.conf:ro` mount unchanged.
2. Any previous `post_start` workaround to `chmod 0600 /var/lib/samba/private/smbpasswd` is no longer needed because the entrypoint enforces `0600` automatically.
3. Tag the outgoing image locally for rollback, switch `image:` to `dgcosenza/samba:latest` (or pinned `@sha256:...`), and run `docker compose up -d samba`.

## Security

- **Trivy** (OS + packages): SARIF uploaded to GitHub Code Scanning; table and JSON reports retained for 90 days; **blocking hard gate** on 0 fixable `CRITICAL`/`HIGH` findings.
- **Grype**: **blocking hard gate** (`only-fixed: true`, severity cutoff `high`); table report retained for 90 days.
- **SBOM & Provenance**: SPDX-JSON SBOM (Syft) and provenance JSON retained for 90 days.
- **Runtime hardening**: `0600` `smbpasswd`, `0700` `/var/lib/samba/private`, `ACCOUNT_*` scrubbed from `smbd` environment, `tini` PID 1, `no-new-privileges:true` compatible.

See [SECURITY.md](SECURITY.md) for responsible disclosure.

## Build Locally

```bash
docker buildx build --platform linux/amd64 --load -t dgcosenza/samba:local .
```

## Update Policy

Every day at **05:32 UTC** (and on push to `main`, pull requests, or manual dispatch), `.github/workflows/daily.yml` runs a 7-step automated pipeline gated by `.github/scripts/public-check.sh`:

1. **Upstream check:** Queries Debian 13 (`trixie`, `trixie-updates`, `trixie-security`) APT package indices to resolve the newest official Samba release, diffs against `versions.json`, and saves `upstream-changes.md` as a 90-day artifact.
2. **Clean rebuild:** Rebuilds on `debian:trixie-slim` with `--no-cache` on scheduled runs and `apt-get upgrade`, generating SPDX-JSON SBOM and provenance artifacts.
3. **Vulnerability fix & hard gates:** Runs Trivy (table, JSON, SARIF upload, and blocking 0 fixable `CRITICAL`/`HIGH` gate) and Grype (blocking 0 fixable `CRITICAL`/`HIGH` gate), retaining all reports for 90 days.
4. **Functional smoke test:** Runs `tests/smoke.sh` to verify env-driven user/share provisioning, authenticated SMB file put/get, `0600` `smbpasswd`, env secret scrubbing, read-only `/etc/samba/smb.conf:ro` mode, and negative healthcheck failure.
5. **Registry publish:** Pushes `latest`, `<version>`, `<version>-<YYYYMMDD>`, and `sha-<short>` tags when Docker Hub credentials are configured.
6. **Automated documentation sync:** Updates `versions.json`, the `<!-- versions:start -->` block in `README.md`, and `CHANGELOG.md` via `github-actions[bot]` (`[skip ci]`, verified by `public-check.sh`), then syncs README and short description to Docker Hub.
7. **Failure alerting:** Opens or updates a single GitHub issue labeled `ci-failure` on any `main` or scheduled failure, and auto-closes it on the next green run.

## Design Decisions

- **Debian 13 (`trixie-slim`) native packages:** Installs `samba`, `smbclient`, `wsdd2`, `avahi-daemon`, and `tini` directly from official Debian 13 repositories — no custom C compilation of archived `wsdd2` tarballs required.
- **Clean read-only `smb.conf` support:** Unlike entrypoints that blindly attempt `cp ... /etc/samba/smb.conf` and emit errors on `:ro` mounts, this entrypoint detects read-only `smb.conf` mounts and preserves them cleanly while still provisioning users and permissions.
- **Strict `0600` credential files & env scrubbing:** Eliminates Samba's insecure-permissions warning on `smbpasswd` and removes `ACCOUNT_*` variables from `smbd`'s environment before `exec`.

## License

- Repository build files, scripts, and documentation: **MIT License** — see [LICENSE](LICENSE).
- Samba: **GPL-3.0-or-later** — see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

## Credits

- [Samba Team](https://www.samba.org/)
- [ServerContainers/samba](https://github.com/ServerContainers/samba) (env-driven configuration convention)
- [Debian Project](https://www.debian.org/)

Maintained by **Daniel G. Cosenza from FNX Labs**.
