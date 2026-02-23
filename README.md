# ordersys-delivery

Public delivery repository for OrderSys install/update artefacts only.

This repository is intentionally static and contains no application source code.

## Purpose

This repo hosts public delivery endpoints for installer/bootstrap and update metadata.

Hosted endpoints:
- `/install`
- `/update/stable.json`
- `/update/X.Y.Z.json`

## Publishing Flow

Production release artefacts are published automatically by the main `ordersys` repository release process.
The expected publish source is signed release output from `ordersys` (`dist/install` and `dist/update/*`).

Placeholders are acceptable only for initial scaffolding/testing and are not acceptable for production publishing.
Signature (`*.sig`) and checksum (`*.sha256`) files must contain real release-generated values for live deployments.

## Deployment

This repository is deployed via Cloudflare Pages:
- no build step
- root directory output
- pure static hosting

## Security

This repository must remain secret-free at all times:
- no private keys
- no API tokens
- no customer-specific data

Only public install/update artefacts should be committed here.
