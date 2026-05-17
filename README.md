# Etherpad — Home Assistant Add-on Repository

[![Builder](https://github.com/ether/home-assistant-addon-etherpad/actions/workflows/builder.yml/badge.svg)](https://github.com/ether/home-assistant-addon-etherpad/actions/workflows/builder.yml)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/ether/home-assistant-addon-etherpad?include_prereleases&sort=semver)](https://github.com/ether/home-assistant-addon-etherpad/releases)
[![Code of Conduct](https://img.shields.io/badge/Code%20of%20Conduct-Contributor%20Covenant-blue.svg)](CODE_OF_CONDUCT.md)

This repository hosts the [Etherpad](https://etherpad.org) Home
Assistant add-on.

## Add to Home Assistant

1. Open **Settings → Add-ons → Add-on Store**.
2. Click the three-dot menu (top right) → **Repositories**.
3. Add: `https://github.com/ether/home-assistant-addon-etherpad`
4. Install **Etherpad** from the store and start it.

Or click the one-click button below:

[![Open your Home Assistant instance and show the add add-on repository dialog with this repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fether%2Fhome-assistant-addon-etherpad)

## Add-ons in this repository

- **[Etherpad](etherpad/DOCS.md)** — realtime collaborative document editor.

## Features

- Pinned to upstream `etherpad/etherpad` Docker image; a daily cron
  auto-bumps when a new Etherpad version ships.
- Persistent SQLite store at `/data/etherpad.db`; MySQL/Postgres
  optional.
- Optional direct HTTPS on port 9001 using HA's `/ssl/` certificate
  layout (`fullchain.pem` + `privkey.pem` — the same files the
  `core_letsencrypt` add-on writes).
- HA ingress for in-frontend access (uses your HA TLS cert).
- Docker `HEALTHCHECK` + supervisor watchdog for auto-restart.
- AppArmor profile bundled.
- Multi-arch images (amd64 + aarch64), Cosign-signed.

## Contributing

Issue and pull-request templates live under `.github/`. By
participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

Bugs in the Etherpad editor itself should go to
<https://github.com/ether/etherpad/issues>; this repo is for the HA
add-on packaging only.

## Source

Upstream Etherpad lives at <https://github.com/ether/etherpad>. This
repository wraps the official `etherpad/etherpad` Docker image with
the Home Assistant supervisor scaffolding (s6-overlay v3, bashio,
ingress, options schema, AppArmor).
