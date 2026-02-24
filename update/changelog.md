## v0.5.7 (2026-02-24)

Added:
- Clearer command output for production operations, including structured sections for status, logs, smoke checks, and diagnostics.
- Improved service visibility in status output with readable state indicators and endpoint summaries.

Fixed:
- Removed noisy missing-version fallback messages from backup flows on installs without a local VERSION file.
- Reduced dense, hard-to-read command output in production operator workflows.

Changed:
- Production command output now uses a consistent presentation style across lifecycle, backup/restore, update, and diagnostics commands.

Security:
- No change to update signature verification, entitlement checks, or runtime security controls.

Upgrade notes:
- No configuration changes required.
- After upgrade, run `ordersys status` and `ordersys doctor` to see the updated operator output format.

