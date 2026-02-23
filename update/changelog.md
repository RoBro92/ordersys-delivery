## v0.5.0 (2026-02-23)

Added:
- Public installer and update delivery flow now publishes each stable release automatically.
- Improved operator landing page with clearer release/status visibility and direct installer/update references.
- Public changelog delivery now follows a stable customer-facing format per release.

Fixed:
- Installer reliability issues that could interrupt setup in some environments.
- Public changelog freshness issues on the delivery homepage.

Changed:
- Release distribution now consistently ships signed update metadata and release-specific changelog content.
- Update/release messaging is clearer for operators evaluating or maintaining installations.

Security:
- Signed update manifest delivery remains enforced for stable releases.
- Public release notes are filtered to user-relevant information only.

Upgrade notes:
- Continue using the same stable update endpoint; no URL changes are required.
- Existing installations can update normally using the standard update process.

