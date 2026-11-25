# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Maintained by **Daniel G. Cosenza from FNX Labs**.

## [Unreleased]

<!-- changelog:auto -->

## [4.22.11] — 2026-11-25

### Automated Daily Build
- Verified components: Samba `4.22.11 (2:4.22.11+dfsg-0+deb13u1)`, Base OS `Debian 13.8 (trixie-slim)`.
- Architectures verified: `linux/amd64, linux/arm64` (native smoke tests + Dive efficiency gate).
- Upstream changes:
  - **Samba:** `4.22.11` (`2:4.22.11+dfsg-0+deb13u1`) -> `4.22.11` (`2:4.22.11+dfsg-0+deb13u1`)
  - **Upstream version changed:** `no`
  - Official Debian 13 (trixie) Samba package `2:4.22.11+dfsg-0+deb13u1` (upstream Samba `4.22.11`).
- Vulnerability gate: **0 fixable Critical/High** in Trivy and Grype (SBOM scan) (32 upstream-unfixed).
- Published multi-arch digest (Docker Hub + GHCR): `dgcosenza/samba@sha256:27901c0142200ac3b5458b2f0c87a8f5457b74963e8b023545009018c89a07eb` (Cosign OIDC signed + SPDX/CycloneDX SBOM + SLSA L3 provenance).

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
