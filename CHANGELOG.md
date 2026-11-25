# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Maintained by **Daniel G. Cosenza from FNX Labs**.

## [Unreleased]

## [2026-11-24]

### Added
- Initial hardened Samba (SMB3) file server image on Debian 13 (`trixie-slim`) with native Debian `samba`, `smbclient`, `wsdd2`, `avahi-daemon`, and `tini`.
- Full env-driven configuration compatibility (`ACCOUNT_*`, `UID_*`, `GROUP_*`, `GROUPS_*`, `SAMBA_VOLUME_CONFIG_*`, `SAMBA_CONF_*`, `SAMBA_GLOBAL_*`) plus clean read-only `/etc/samba/smb.conf:ro` mount support.
- Functional `smbclient -L 127.0.0.1 -N` healthcheck, smoke test suite, and 7-step automated daily CI pipeline.

### Security
- Enforced `0600` permissions on `/var/lib/samba/private/smbpasswd` (and `0700` on `/var/lib/samba/private`) and scrubbed `ACCOUNT_*` secrets before `exec smbd`.
- Verified 0 fixable Critical/High findings in both Trivy and Grype.
