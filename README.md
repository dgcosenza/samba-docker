# Samba (SMB3) File Server on Debian 13 (trixie)

[![Daily Samba image](https://github.com/dgcosenza/samba-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/samba-docker/actions/workflows/daily.yml)
[![Packaging License: MIT](https://img.shields.io/badge/packaging-MIT-blue.svg)](https://github.com/dgcosenza/samba-docker/blob/main/LICENSE)
[![Upstream License: GPL-3.0-or-later](https://img.shields.io/badge/upstream-GPL--3.0--or--later-green.svg)](https://gitlab.com/samba-team/samba/-/blob/master/COPYING)
[![Signed with Cosign](https://img.shields.io/badge/signed-cosign%20OIDC-blueviolet.svg)](#supply-chain-verification)
[![SLSA Level 3](https://img.shields.io/badge/SLSA-Level%203-brightgreen.svg)](#supply-chain-verification)
[![Architectures](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-informational.svg)](#supported-architectures)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/dgcosenza/samba-docker/badge)](https://scorecard.dev/viewer/?uri=github.com/dgcosenza/samba-docker)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/17153/badge)](https://www.bestpractices.dev/projects/17153)
[![Docker Pulls](https://img.shields.io/docker/pulls/dgcosenza/samba)](https://hub.docker.com/r/dgcosenza/samba)
[![Docker Image Size](https://img.shields.io/docker/image-size/dgcosenza/samba/latest)](https://hub.docker.com/r/dgcosenza/samba)
[![Latest Release](https://img.shields.io/github/v/release/dgcosenza/samba-docker?label=version)](https://github.com/dgcosenza/samba-docker/releases)

A hardened, multi-arch **Samba (SMB3)** file server container image on **Debian 13 (`trixie-slim`)**, featuring drop-in environment-driven user/share configuration (`ACCOUNT_*`, `UID_*`, `SAMBA_VOLUME_CONFIG_*`), clean read-only mounted `/etc/samba/smb.conf` support, `0600` password database permissions, `tini` PID 1, and functional `smbclient` healthchecks, maintained by **Daniel G. Cosenza from FNX Labs**.

- **Docker Hub:** [`dgcosenza/samba`](https://hub.docker.com/r/dgcosenza/samba)
- **GitHub Container Registry (GHCR):** [`ghcr.io/dgcosenza/samba`](https://github.com/dgcosenza/samba-docker/pkgs/container/samba) (identical signed multi-arch digest)
- **Source Repository:** [`dgcosenza/samba-docker`](https://github.com/dgcosenza/samba-docker)
- **Upstream Application:** [Samba](https://www.samba.org/) (`GPL-3.0-or-later`)

---

## Current Versions

<!-- versions:start -->
| Component | Resolved Version |
| --- | --- |
| Samba | `4.22.11 (2:4.22.11+dfsg-0+deb13u1)` |
| Base OS | `Debian 13.8 (trixie-slim)` |
| Architectures | `linux/amd64, linux/arm64` |
| Uncompressed size (per arch) | `amd64: 68.5 MB, arm64: 216.9 MB` |
| Last verified build (UTC) | `2026-11-26` |
| Published multi-arch digest | `dgcosenza/samba@sha256:c59f4d9ec91f4214355beac39903923f54ca1c1af132fa42effa47ea3a6ee7e5` |
| GHCR mirror | `ghcr.io/dgcosenza/samba@sha256:c59f4d9ec91f4214355beac39903923f54ca1c1af132fa42effa47ea3a6ee7e5` |
| Supply chain | Cosign OIDC signed + SPDX & CycloneDX SBOM attestations + SLSA Build L3 provenance |
| Security gate (Trivy + Grype on SBOM) | **0 fixable findings of any severity** (32 upstream-unfixed) |

**Recent upstream changes:**
- **Samba:** `4.22.11` (`2:4.22.11+dfsg-0+deb13u1`) -> `4.22.11` (`2:4.22.11+dfsg-0+deb13u1`)
- **Upstream version changed:** `no`
- Official Debian 13 (trixie) Samba package `2:4.22.11+dfsg-0+deb13u1` (upstream Samba `4.22.11`).
<!-- versions:end -->

---

## Supported Tags & Tag Policy

Identical multi-arch OCI digests are published to **Docker Hub** (`dgcosenza/samba`) and **GHCR** (`ghcr.io/dgcosenza/samba`), accompanied by an automated signed [GitHub Release](https://github.com/dgcosenza/samba-docker/releases):

| Tag | Policy | Description |
| --- | --- | --- |
| `<version>-<YYYYMMDD>` (e.g. `4.22.11-20261125`) | **Immutable** | Date-stamped daily rebuild pinning the Samba version and UTC build date. |
| `sha-<short>` | **Immutable** | Packaging repository Git commit tag. |
| `<version>` (e.g. `4.22.11`) | Moving | Latest verified Debian 13 security rebuild of that Samba release. |
| `latest` | Moving | Latest verified build tracking the newest official Debian 13 Samba package. |

**Production pinning:** Pin by immutable registry digest rather than an unpinned moving tag:

```yaml
image: dgcosenza/samba:latest@sha256:<digest>
# or via GitHub Container Registry (identical digest):
image: ghcr.io/dgcosenza/samba:latest@sha256:<digest>
```

---

## Supported Architectures

| Architecture | Status | Verification |
| --- | --- | --- |
| `linux/amd64` | **Published & natively tested** | Built, smoke-tested (env-driven + `:ro` `smb.conf`, SMB3 auth R/W, `0600` `smbpasswd`, env secret scrub), Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native x86_64 CI runners. |
| `linux/arm64` | **Published & natively tested** | Built, smoke-tested, Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native ARM64 CI runners. |

---

## Quick Start

### Docker CLI

```bash
docker run -d --name samba \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --cap-add SETUID \
  --cap-add SETGID \
  --cap-add CHOWN \
  --cap-add DAC_OVERRIDE \
  --cap-add FOWNER \
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

### Hardened Docker Compose

See [`docker-compose.example.yml`](https://github.com/dgcosenza/samba-docker/blob/main/docker-compose.example.yml):

```yaml
services:
  samba:
    image: dgcosenza/samba:latest
    restart: unless-stopped
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
      - SETUID
      - SETGID
      - CHOWN
      - DAC_OVERRIDE
      - FOWNER
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

---

## Configuration

### Environment Variables

Drop-in compatible with the `ServerContainers/samba` env-driven scheme:

| Variable | Description | Default |
| --- | --- | --- |
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

### Volumes, Ports, and Privileges

| Path / Port | Purpose |
| --- | --- |
| `/shares` | Base mount point for shared host directories |
| `/etc/samba/smb.conf` | Optional read-only custom `smb.conf` mount (preserved verbatim when `:ro` while still provisioning `ACCOUNT_*`/`UID_*`/`GROUP_*`) |
| `445/tcp` | SMB2/SMB3 over TCP |
| `139/tcp`, `137/udp`, `138/udp` | Optional NetBIOS (disabled when `NETBIOS_DISABLE=1`) |

`smbd` starts as `root` strictly to bind privileged port `445` and switch effective UID/GID per authenticated SMB session and `force user` directive; dropping all capabilities except `NET_BIND_SERVICE`, `SETUID`, `SETGID`, `CHOWN`, `DAC_OVERRIDE`, and `FOWNER` alongside `no-new-privileges:true` minimizes container privileges. Account passwords are stored with strict `0600` permissions inside `0700 /var/lib/samba/private` and scrubbed from `smbd`'s environment before `exec`.

---

## Healthcheck

```bash
smbclient -L 127.0.0.1 -N >/dev/null 2>&1
```

---

## Upgrade and Migration from `ghcr.io/servercontainers/samba`

1. Keep your existing `samba.env` (`ACCOUNT_*`, `UID_*`), volume mounts, and optional `/etc/samba/smb.conf:ro` mount unchanged.
2. Any previous `post_start` workaround to `chmod 0600 /var/lib/samba/private/smbpasswd` is no longer needed because the entrypoint enforces `0600` automatically.
3. Tag the outgoing image locally for rollback, switch `image:` to `dgcosenza/samba:latest@sha256:<digest>` (or GHCR), and run `docker compose up -d samba`.

---

## Supply-Chain Verification

Every published digest (multi-arch index and per-architecture manifests) on both Docker Hub and GHCR is keyless-signed with **Sigstore Cosign** (GitHub OIDC), attested with **SPDX** and **CycloneDX** SBOMs, and backed by **SLSA Build L3** provenance (`actions/attest-build-provenance`).

### Verify image signature with Cosign

```bash
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/samba-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/samba:latest

# Or against Docker Hub (identical digest):
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/samba-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  dgcosenza/samba:latest
```

### Verify SPDX / CycloneDX SBOM attestations

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/samba-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/samba@sha256:<arch-digest>
```

### Verify SLSA Build Provenance

```bash
gh attestation verify oci://ghcr.io/dgcosenza/samba:latest --owner dgcosenza
```

---

## Security

- **Preflight gates:** Every push and PR runs **Hadolint** (blocking on warning+), **Gitleaks** secret scanning across git history, and **public-content/attribution** checks.
- **Vulnerability scan policy (all severities with a fix):** Every build generates **SPDX** and **CycloneDX** SBOMs with **Syft** per architecture, scans with **Trivy** (table, JSON, SARIF upload, blocking `--ignore-unfixed` gate) and **Grype** scanning the SPDX SBOM (`--only-fixed --fail-on negligible`), and enforces a **Dive** efficiency gate (`>= 95%`).
- **Runtime hardening:** `0600` `smbpasswd`, `0700` `/var/lib/samba/private`, `ACCOUNT_*` scrubbed from `smbd` environment, `tini` PID 1, `no-new-privileges:true` compatible.
- **Dependency automation:** Renovate (`renovate.json`) pins base image digests and GitHub Action commit SHAs; Dependabot security alerts and OpenSSF Scorecard monitoring are enabled.
- See [`SECURITY.md`](https://github.com/dgcosenza/samba-docker/blob/main/SECURITY.md) for responsible disclosure.

---

## Build Locally

```bash
docker buildx build --platform linux/amd64 --load -t dgcosenza/samba:local .
```

---

## Update Policy

[`.github/workflows/daily.yml`](https://github.com/dgcosenza/samba-docker/blob/main/.github/workflows/daily.yml) runs automatically every day at **05:32 UTC**, on pushes to `main`, on pull requests (verification only), and via `workflow_dispatch`:

1. **Preflight & upstream check:** Runs public-content checks, **Hadolint**, and **Gitleaks**; queries Debian 13 (`trixie`, `trixie-updates`, `trixie-security`) APT feeds for the latest Samba package and resolves the latest `debian:trixie-slim` digest, emitting `upstream-changes.md`.
2. **Multi-arch no-cache rebuild:** Rebuilds natively on `linux/amd64` and `linux/arm64` runners with `--no-cache` on schedule and `apt-get upgrade`.
3. **Smoke, Dive & vulnerability gates:** Runs [`tests/smoke.sh`](https://github.com/dgcosenza/samba-docker/blob/main/tests/smoke.sh) natively on both architectures, enforces the **Dive** efficiency gate (`>= 95%`), generates **Syft** SPDX + CycloneDX SBOMs per arch, and gates publication on **0 fixable findings of any severity** in both **Trivy** and **Grype** (scanning the SPDX SBOM).
4. **Dual-registry publish & supply-chain signing:** Assembles the multi-arch OCI manifest index on **GHCR** (`ghcr.io/dgcosenza/samba`) and mirrors the identical digest to **Docker Hub** (`dgcosenza/samba`) with tags `latest`, `<version>`, `<version>-<YYYYMMDD>`, and `sha-<short>`; signs every digest and attaches SPDX/CycloneDX SBOM attestations via **Cosign** keyless OIDC; emits **SLSA Build L3** provenance; and publishes a signed **GitHub Release** with checksums and SBOMs.
5. **Automated documentation sync:** Commits updated `versions.json`, the README `Current Versions` block, and a dated `CHANGELOG.md` entry via `github-actions[bot]` (`[skip ci]`, validated by `public-check.sh`), then syncs the Docker Hub overview and short description.
6. **Failure alerting:** Opens or updates a single GitHub issue labeled `ci-failure` on any `main` or scheduled failure, and auto-closes it on the next green run.

---

## Design Decisions

- **Debian 13 (`trixie-slim`) native packages:** Installs `samba`, `smbclient`, `wsdd2`, `avahi-daemon`, and `tini` directly from official Debian 13 repositories — no custom compilation of archived `wsdd2` tarballs required.
- **Clean read-only `smb.conf` support:** Detects read-only `/etc/samba/smb.conf` mounts and preserves them verbatim while still provisioning users and enforcing `0600` credentials.
- **Hadolint `DL3008` ignore:** Daily `--no-cache` security rebuilds intentionally pull the newest Debian 13 security updates via `apt-get`.
- **Dive `highestUserWastedPercent: 0.15`:** Overall image efficiency remains strictly gated at `>= 95%`. Because daily `apt-get -y upgrade` overwrites ~5 MB of `debian:trixie-slim` base files against a compact Samba layer, `highestUserWastedPercent` is tuned to `0.15` rather than squashing away shared Debian base layers.

---

## License

This repository follows a clear packaging-vs-upstream license split:

- **Container packaging, entrypoint scripts, CI workflows, and documentation (`packaging: MIT`):** Licensed under the [MIT License](https://github.com/dgcosenza/samba-docker/blob/main/LICENSE) — copyright **Daniel G. Cosenza from FNX Labs**.
- **Bundled upstream software — Samba (`upstream: GPL-3.0-or-later`):** Copyright the Samba Team — licensed under the [GNU General Public License v3.0 or later](https://gitlab.com/samba-team/samba/-/blob/master/COPYING).

Full third-party notices are maintained in [`THIRD-PARTY-NOTICES.md`](https://github.com/dgcosenza/samba-docker/blob/main/THIRD-PARTY-NOTICES.md). Release history is maintained in [`CHANGELOG.md`](https://github.com/dgcosenza/samba-docker/blob/main/CHANGELOG.md).

## Credits

- [Samba Team](https://www.samba.org/)
- [ServerContainers/samba](https://github.com/ServerContainers/samba) (env-driven configuration convention)
- [Debian Project](https://www.debian.org/)

Maintained by **Daniel G. Cosenza from FNX Labs**.
