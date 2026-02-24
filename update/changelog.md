## v0.5.6 (2026-02-24)

Added:
- Production command-line experience now presents a production-only command set on installed systems.
- Installer repair/update flows now consistently route updates through the licence-gated updater path.

Fixed:
- Closed a path where installer re-run actions could apply updates outside the normal update entitlement checks.
- Improved resilience when a host has a launcher command but missing local CLI payload files.

Changed:
- Public key material used for licence verification and installer-distributed trust has been rotated to the new production key set.
- Production repair runs now preserve currently installed image references instead of implicitly moving to newest release.

Security:
- Update entitlement checks are now enforced consistently across normal update and installer-triggered update paths.
- Production hosts no longer expose dev-oriented operator commands by default.

Upgrade notes:
- After upgrading, use `ordersys update` (or the hosted updater) for all version changes.
- If you manage your own token issuer, sign new tokens with the rotated production private key that matches this release.

