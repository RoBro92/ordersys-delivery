## v0.5.2 (2026-02-23)

Added:
- Production installer support for Debian 13 hosts.

Fixed:
- Debian version detection now correctly recognizes Debian 13 during install checks.

Changed:
- Debian 12 and Debian 13 are now the validated installer targets.
- Public supported-host guidance now reflects Debian 12 and Debian 13 support.

Security:
- No change to manifest signing or updater verification requirements.

Upgrade notes:
- Existing Debian 12 installations are unaffected.
- Debian 13 hosts can use the standard installer command with no extra flags.

