## v0.5.4 (2026-02-23)

Added:
- Installer update mode now re-applies licence public-key wiring automatically on existing installations.

Fixed:
- Licence token check no longer returns an internal server error when verifier/runtime failures occur.
- Production backend now consistently reads the bundled licence public key file in containerised deployments.

Changed:
- Production compose/runtime assets now mount the configured licence public-key file read-only into backend.

Security:
- Licence verification remains offline-first and signature-based; this release improves reliability of key provisioning only.

Upgrade notes:
- If you hit token-check errors on earlier versions, update to v0.5.4 and rerun the licence check.

