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

Release artefacts are published automatically by the main `ordersys` repository release process.

## Deployment

This repository is deployed via Cloudflare Pages:
- no build step
- root directory output
- pure static hosting

## Security

No secrets, private keys, or customer-specific data are stored in this repository.
