# Changelog

## 0.3.1

## Fixes
- Installer reliability fix: avoid `set -euo pipefail` abort during secret generation.
- `random_secret()` now generates 48-character alphanumeric secrets without SIGPIPE failure paths.

## Notes
- No functional change to deployment topology.
- Delivery artefacts are published automatically to `ordersys-delivery` by release workflow.

## 0.3.0

Release date: 2026-02-23

## Summary
- Delivery pipeline update to publish installer/update artefacts into `ordersys-delivery`.
- Delivery endpoint hardening and landing-page improvements for operator install/update workflows.

## Operational Notes
- Stable release artefacts are published to `ordersys-delivery` for Cloudflare Pages hosting.
- Installer endpoint remains:
  - `https://ordersys.stonewallmedia.co.uk/install`
- Stable manifest endpoint remains:
  - `https://ordersys.stonewallmedia.co.uk/update/stable.json`

## Security and Delivery
- Delivery repository remains public and secret-free.
- Signed update manifests and checksum sidecars are expected in published stable artefacts.

## 0.2.0

Release date: 2026-02-22

## Summary
OrderSys v0.2.0 closes the milestone delivery programme and transitions the repository to maintenance mode. The release finalises production hardening, delivery acceptance evidence, and operational documentation.

## Major Architectural and Security Changes
- React SPA is the only production-served frontend; legacy frontend routes are blocked in production ingress and frontend Nginx.
- Auth moved to memory-only access tokens + rotating refresh-cookie sessions (HttpOnly cookie flow), with a temporary bearer-compatibility window.
- Updater hardened with signed manifest verification, strict fetch policy controls, dry-run support, and automatic rollback on migrate/health-gate failure.
- Login rate limiting is bounded and proxy-aware, with trusted client-IP extraction model for both rate limiting and audit attribution.
- Receiving/order lifecycle concurrency correctness hardened to prevent stale order status under concurrent receipts.
- Import pipeline updated for streaming/chunked processing with configurable safety limits to prevent OOM and reduce N+1 query amplification.
- Backend dependency installation is lock-driven and reproducible in Docker runtime builds.

## Milestone Completion Status
All Milestones 1-12 are now closed in the archived governance record:
- Canonical archive: `docs/archive/milestones/MILESTONES.md`
- Delivery acceptance evidence (Milestone 10): `docs/ACCEPTANCE_M10.md`
- Reconciliation and audit history: `docs/archive/reconciliation/` and `docs/archive/governance/`

## Supported Runtime Topology
- Production topology (supported):
  - `proxy` (Nginx) -> `frontend` (Nginx static SPA) + `backend` (FastAPI) + `db` (Postgres) + `redis`
  - Default mode is LAN-first HTTP with optional HTTPS enforcement controls.
- Development topology:
  - same-origin proxy profile for frontend/API integration testing,
  - direct mode available for targeted debugging.

## Upgrade Path Assumptions
- Upgrades target deployed stacks using `runtime/prod` templates and `ordersys update` flow.
- Update manifests are signed and verified before use; unsigned/invalid manifests fail closed.
- Backups are expected to succeed before update mutation steps; rollback depends on valid snapshot + restart path.
- DB migrations are forward-applied by updater; rollback assumes pre-update backup artifacts are available.

## Known Non-Blocking Limitations
- Debian 12 installer acceptance evidence is simulation-backed in this repo execution context (production-profile fidelity, no fresh VM provisioning in-CI).
- Remaining medium/low security debt (for example key-material hygiene and additional policy hardening) is tracked in archived audit records.
- Legacy bearer compatibility remains temporarily available for migration; operators should plan to disable it after client cutover.

## Documentation
- Product/operator docs: `docs/product/`
- Developer docs: `docs/developer/`
- Historical governance and milestone archive: `docs/archive/`
- Maintenance policy: `MAINTENANCE_MODE.md`

