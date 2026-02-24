# Internal State (2026-02-24)

This is the handover snapshot for paused development.

## Repository Snapshot
- Repository: `ordersys-delivery`
- Branch: `main`
- Current delivery version marker: `VERSION` -> `0.5.8`
- Current stable manifest: `update/stable.json` -> `latest_version: 0.5.8`

## Delivery Purpose
- Public static delivery endpoint only.
- No product source code.
- No secrets, private keys, or customer data.
- Cloudflare Pages static hosting (no build step).

## Active Public Endpoints
- `/` (landing page)
- `/install` (installer script)
- `/update` (302 redirect to `/update.sh`)
- `/update.sh` (hosted updater wrapper)
- `/update/stable.json` (+ `.sig`, `.sha256`)
- `/update/0.5.8.json` (+ `.sig`, `.sha256`)
- `/update/changelog.md`

## Update/Installer Behavior
- `/update.sh` verifies signed manifest metadata before delegating to local host CLI:
  - `ordersys update`
- Updater supports local key recovery path from installer payload if manifest verification fails with local key.
- Installer script includes runtime compose/template payload and host-level CLI bootstrap (`/usr/local/bin/ordersys`).

## Contract and CI Guardrails
- Validation script: `scripts/validate-delivery.sh`
- CI workflow: `.github/workflows/ci.yml`
- Guardrails include:
  - private-key pattern scanning,
  - required artefact path checks,
  - JSON schema/value checks,
  - SemVer manifest naming checks,
  - current-release-only enforcement (historical versioned artefacts rejected),
  - placeholder signature/checksum rejection (except temporary explicit allowance path in CI).

## Publishing Source of Truth
- Stable releases are published from `ordersys` release workflow (`.github/workflows/release.yml`).
- Delivery publish job copies:
  - `dist/install` (or `dist/install.sh` fallback),
  - `dist/update/stable.json(.sig/.sha256)`,
  - `dist/update/<version>.json(.sig/.sha256)`,
  - `dist/update/changelog.md`,
  - `VERSION`.
- Historical `update/*.json|*.sig|*.sha256` files are removed each publish before current release files are copied.

## Resume Checklist
1. Confirm delivery `main` points to expected stable version:
   - `cat update/stable.json`
   - `cat VERSION`
2. Confirm delivery guardrails:
   - `scripts/validate-delivery.sh`
3. If performing next stable release from `ordersys`, verify post-publish:
   - manifest version,
   - changelog content,
   - installer/update script endpoints.
