## v0.5.1 (2026-02-23)

Added:
- Stronger licence entitlement checks before updates are applied, with clearer operator messaging when an update is not permitted.

Fixed:
- Trial behaviour could previously be too permissive for update and data-transfer operations in some flows.

Changed:
- Trial licences are now limited to 7 days with tighter server-side enforcement.
- Public update delivery now exposes only the current stable release payload.

Security:
- Trial licences can no longer run in-place updates.
- Trial licences are now blocked from database transfer operations (import/export/restore style actions).
- Update eligibility is enforced server-side before updater execution continues.

Upgrade notes:
- Trial environments will not be able to run update actions until a paid licence is applied.
- Existing annual/lifetime installations should continue using the normal update process.

