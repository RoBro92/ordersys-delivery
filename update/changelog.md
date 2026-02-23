## v0.5.5 (2026-02-23)

Added:
- Installer now provisions a host-level `ordersys` command at `/usr/local/bin/ordersys`.

Fixed:
- Hosted updater now attempts key recovery from the installer payload when local manifest key verification fails.
- Installer now bundles the local CLI payload so operator commands are available on installed hosts.

Changed:
- Release automation now derives installer-embedded public key from the active manifest-signing private key.

Security:
- Signed manifest verification remains mandatory; this release removes key-drift risk between signed artefacts and installer-pinned key.

Upgrade notes:
- If `ordersys` command is missing on an older host, run installer repair once.
- If updater previously failed with manifest signature errors, rerun:
  - `curl -fsSL https://ordersys.stonewallmedia.co.uk/update.sh | bash`

