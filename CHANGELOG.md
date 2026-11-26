# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Maintained by **Daniel G. Cosenza from FNX Labs**.

## [Unreleased]

<!-- changelog:auto -->

## [4.22.11] — 2026-11-26

### Automated Daily Build
- Verified components: Samba `4.22.11 (2:4.22.11+dfsg-0+deb13u1)`, Base OS `Debian 13.8 (trixie-slim)`.
- Architectures verified: `linux/amd64, linux/arm64` (native smoke tests + Dive efficiency gate).
- Upstream changes:
  - **Samba:** `4.22.11` (`2:4.22.11+dfsg-0+deb13u1`) -> `4.22.11` (`2:4.22.11+dfsg-0+deb13u1`)
  - **Upstream version changed:** `no`
  - Official Debian 13 (trixie) Samba package `2:4.22.11+dfsg-0+deb13u1` (upstream Samba `4.22.11`).
- Vulnerability gate: **0 fixable findings of any severity** in Trivy and Grype (SBOM scan) (32 upstream-unfixed).
- Published multi-arch digest (Docker Hub + GHCR): `dgcosenza/samba@sha256:c59f4d9ec91f4214355beac39903923f54ca1c1af132fa42effa47ea3a6ee7e5` (Cosign OIDC signed + SPDX/CycloneDX SBOM + SLSA L3 provenance).
---

## [4.22.11] — 2026-11-25

### Automated Daily Build
- Verified components: Samba `4.22.11 (2:4.22.11+dfsg-0+deb13u1)`, Base OS `Debian 13.8 (trixie-slim)`.
- Architectures verified: `linux/amd64, linux/arm64` (native smoke tests + Dive efficiency gate).
- Upstream changes:
  - **Samba:** `4.22.11` (`2:4.22.11+dfsg-0+deb13u1`) -> `4.22.11` (`2:4.22.11+dfsg-0+deb13u1`)
  - **Upstream version changed:** `no`
  - Official Debian 13 (trixie) Samba package `2:4.22.11+dfsg-0+deb13u1` (upstream Samba `4.22.11`).
- Vulnerability gate: **0 fixable Critical/High** in Trivy and Grype (SBOM scan) (32 upstream-unfixed).
- Published multi-arch digest (Docker Hub + GHCR): `dgcosenza/samba@sha256:c3e3e134a01019a02f42e7bf820cf696e408eb371bfb0c0267478c94d5c8e384` (Cosign OIDC signed + SPDX/CycloneDX SBOM + SLSA L3 provenance).
---

---

## [2026-11-24]

### Added
- Initial hardened Samba (SMB3) file server image on Debian 13 (`trixie-slim`) with native Debian `samba`, `smbclient`, `wsdd2`, `avahi-daemon`, and `tini`.
- Full env-driven configuration compatibility (`ACCOUNT_*`, `UID_*`, `GROUP_*`, `GROUPS_*`, `SAMBA_VOLUME_CONFIG_*`, `SAMBA_CONF_*`, `SAMBA_GLOBAL_*`) plus clean read-only `/etc/samba/smb.conf:ro` mount support.
- Functional `smbclient -L 127.0.0.1 -N` healthcheck, smoke test suite, multi-arch (`linux/amd64`, `linux/arm64`), Cosign OIDC signing, SPDX/CycloneDX SBOM attestations, SLSA Build L3 provenance, dual-registry publishing (GHCR + Docker Hub), and automated daily CI pipeline.

### Security
- Enforced `0600` permissions on `/var/lib/samba/private/smbpasswd` (and `0700` on `/var/lib/samba/private`) and scrubbed `ACCOUNT_*` secrets before `exec smbd`.
- Verified 0 fixable Critical/High findings in both Trivy and Grype.
