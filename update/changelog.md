## v0.5.8 (2026-02-24)

Added:
- A beta notice banner is now shown in the app header reminding operators to take regular database backups.
- The header version now shows an update-available badge when a newer stable release is detected.

Fixed:
- Browser tab title now consistently shows `OrderSys`.
- Admin System Update panel now uses clearer wording:
  - Status shows `Connected` when update checks succeed.
  - Entitlement reason shows `Valid Licence` in green when update entitlement is active.
- Removed low-value update-source policy text from the Admin System Update display to reduce clutter.

Changed:
- Primary app URLs now use clean operator paths (`/admin`, `/imports`, etc.) instead of `react-*` paths.
- Legacy `react-*` links remain supported and normalize to the new clean URL format.
- Production CLI help/command surface is now simplified for installed production systems.
- Update flow output is cleaner during image pull/apply steps.

Security:
- No change to signed manifest enforcement or licence entitlement controls.

Upgrade notes:
- Existing bookmarks to legacy `react-*` routes continue to work and will redirect to clean URLs.
- Use `ordersys update` (or hosted updater) as normal; no update-source change is required.

