#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: Etherpad
# Install the user's declared plugins on startup. Etherpad's own
# `/admin/plugins` UI still works for ad-hoc installs, but those don't
# survive addon updates (they go into the image filesystem at
# /opt/etherpad-lite/node_modules). This script makes the `plugins:` option
# in the addon config the source of truth: every boot we reinstall anything
# in the list that isn't already present, which survives image rebuilds.
# ==============================================================================
set -e

EP_DIR=/opt/etherpad-lite

# bashio::config 'plugins' returns the raw JSON array; empty list means skip.
plugins=$(bashio::config 'plugins')
if [ "${plugins}" = "null" ] || [ -z "${plugins}" ]; then
  bashio::log.info "No plugins declared in addon config; skipping installer."
  exit 0
fi

count=$(echo "${plugins}" | jq -r 'length')
if [ "${count}" -eq 0 ]; then
  bashio::log.info "Empty plugin list; skipping installer."
  exit 0
fi

bashio::log.info "Installing ${count} declared plugin(s)..."

cd "${EP_DIR}"
for plugin in $(echo "${plugins}" | jq -r '.[]'); do
  if [ -d "${EP_DIR}/node_modules/${plugin}" ]; then
    bashio::log.info "  ${plugin}: already installed, skipping"
    continue
  fi
  bashio::log.info "  ${plugin}: installing..."
  if pnpm run plugins i "${plugin}" 2>&1 | tail -5; then
    bashio::log.info "  ${plugin}: OK"
  else
    bashio::log.warning "  ${plugin}: install failed (check the npm package name); continuing"
  fi
done

bashio::log.info "Plugin install complete."
