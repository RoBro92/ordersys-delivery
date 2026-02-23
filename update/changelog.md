## v0.5.3 (2026-02-23)

Added:
- New hosted update entrypoint: `https://ordersys.stonewallmedia.co.uk/update.sh`.
- Expanded local operator CLI commands for start/stop, version visibility, and backup inventory/retention.
- Full-system backup and restore commands for DB, config, and runtime volume data.

Fixed:
- Admin release changelog view now prefers live delivery changelog content instead of a bundled placeholder summary.
- LAN HTTP login lockout scenario caused by refresh-cookie mode mismatch in some production compose environments.
- Installer/update operator messaging and terminal completion guidance.

Changed:
- Update flow now includes stronger preflight checks, optional OS update prompts, changelog preview, structured logging, and backup-aware rollback guidance.
- Backup layout is standardised under `/var/lib/ordersys/backups` with `latest` pointer support.
- Delivery updater endpoint delegates to the installed local `ordersys update` flow to keep update logic on the host.

Security:
- Signed manifest verification and strict update-source policy remain mandatory before update mutations.
- Licence entitlement checks continue to block non-entitled updates and trial DB transfer operations.

Upgrade notes:
- Use `ordersys version` to confirm installed/latest/eligibility state after upgrade.
- For hosted update usage, run: `curl -fsSL https://ordersys.stonewallmedia.co.uk/update.sh | bash`.

