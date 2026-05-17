# Etherpad — Home Assistant Add-on Repository

This repository hosts the [Etherpad](https://etherpad.org) Home
Assistant add-on.

## Add to Home Assistant

1. Open **Settings → Add-ons → Add-on Store**.
2. Click the three-dot menu (top right) → **Repositories**.
3. Add: `https://github.com/ether/home-assistant-addon-etherpad`
4. Install **Etherpad** from the store and start it.

## Add-ons in this repository

- **[Etherpad](etherpad/README.md)** — realtime collaborative document editor.

## Source

Upstream Etherpad lives at <https://github.com/ether/etherpad>. This
repository wraps the official `etherpad/etherpad` Docker image with the
Home Assistant supervisor scaffolding (s6-overlay v3, ingress, options
schema).
