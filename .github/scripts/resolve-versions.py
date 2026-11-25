#!/usr/bin/env python3
"""Resolve latest official Samba package version in Debian 13 (trixie + security)."""

from __future__ import annotations

import json
import lzma
import os
import re
import urllib.request
from pathlib import Path


def fetch_bytes(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "dgcosenza-samba-docker-ci"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read()


def ver_tuple(v: str) -> tuple[int, ...]:
    core = v.split(":", 1)[-1].split("+", 1)[0].split("-", 1)[0]
    return tuple(int(x) for x in re.findall(r"\d+", core))


def find_samba_deb(pkg_text: str) -> list[str]:
    found: list[str] = []
    cur = ""
    for line in pkg_text.splitlines():
        if line.startswith("Package: "):
            cur = line.split(": ", 1)[1].strip()
        elif line.startswith("Version: ") and cur == "samba":
            found.append(line.split(": ", 1)[1].strip())
    return found


def resolve_samba() -> tuple[str, str]:
    urls = [
        "https://deb.debian.org/debian-security/dists/trixie-security/main/binary-amd64/Packages.xz",
        "https://deb.debian.org/debian/dists/trixie-updates/main/binary-amd64/Packages.xz",
        "https://deb.debian.org/debian/dists/trixie/main/binary-amd64/Packages.xz",
    ]
    candidates: list[str] = []
    for url in urls:
        try:
            raw = lzma.decompress(fetch_bytes(url)).decode("utf-8", errors="replace")
            candidates.extend(find_samba_deb(raw))
        except Exception:
            continue
    if not candidates:
        raise SystemExit("ERROR: Could not resolve Samba version from Debian 13 feeds")
    candidates.sort(key=lambda s: (ver_tuple(s), s), reverse=True)
    deb_ver = candidates[0]
    m = re.search(r"(\d+\.\d+\.\d+)", deb_ver)
    upstream = m.group(1) if m else deb_ver
    return upstream, deb_ver


def main() -> None:
    override = os.environ.get("OVERRIDE_SAMBA", "").strip()
    if override:
        upstream, deb_ver = override, override
        notes = f"Manual override requested: Samba {override}."
    else:
        upstream, deb_ver = resolve_samba()
        notes = f"Official Debian 13 (trixie) Samba package `{deb_ver}` (upstream Samba `{upstream}`)."

    prev = {}
    vpath = Path("versions.json")
    if vpath.exists():
        prev = json.loads(vpath.read_text(encoding="utf-8"))
    prev_deb = prev.get("samba_deb_version", "")
    prev_ver = prev.get("samba_version", "")
    changed = deb_ver != prev_deb

    md = [
        "# Upstream changes — Samba on Debian 13",
        "",
        f"- **Samba:** `{prev_ver or 'none'}` (`{prev_deb or 'none'}`) -> `{upstream}` (`{deb_ver}`)",
        f"- **Upstream version changed:** `{'yes' if changed else 'no'}`",
        "",
        "## Release details",
        "",
        notes,
        "",
    ]
    Path("upstream-changes.md").write_text("\n".join(md), encoding="utf-8")

    outputs = {
        "samba_version": upstream,
        "samba_deb_version": deb_ver,
        "prev_samba_version": prev_ver,
        "upstream_changed": "true" if changed else "false",
    }
    gh_out = os.environ.get("GITHUB_OUTPUT")
    if gh_out:
        with open(gh_out, "a", encoding="utf-8") as fh:
            for k, v in outputs.items():
                fh.write(f"{k}={v}\n")
    for k, v in outputs.items():
        print(f"{k}={v}")


if __name__ == "__main__":
    main()
