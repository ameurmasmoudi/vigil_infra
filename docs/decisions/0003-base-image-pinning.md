# 0003: Base image pinning and verification

- **Status:** Accepted
- **Date:** 2026-11-17

## Context

Every VM boots from a cloud image: a pre-installed disk that cloud-init configures on first boot. `current` image
URLs change content without notice, and the libvirt provider can download a URL but cannot verify a checksum.

## Options

1. **Provider downloads a `current` URL:** simplest; not reproducible and not verified.
2. **Provider downloads a dated release URL:** reproducible, still not verified, and re-downloaded (~600 MB) whenever
   the base volume is recreated.
3. **Script downloads a dated release once into a local cache; OpenTofu verifies the file's SHA-256 before using
   it.**

## Decision

Option 3, with Ubuntu 24.04 LTS (most tested with k3s; ufw and unattended-upgrades included).

- `terraform/image.json` is the single pin (release `20261017`, URL, SHA-256), read by both tools.
- `terraform/fetch-image.sh` downloads into `~/.cache/vigil/images/` with retries and resume, and checks the
  checksum.
- A `precondition` on the base volume compares `filesha256()` of the cached file with the pin; a mismatch stops
  the plan before anything is created.
- Each VM disk is a thin copy-on-write overlay on the base volume.

## Consequences

- Reproducible and tamper-evident; rebuilds never re-download the image.
- One extra command before the first apply. The plan hashes a ~600 MB file, which takes a moment.
- Updating the OS means changing `image.json`, which recreates the base volume and every VM.
