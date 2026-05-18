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
OPTIONS=/data/options.json

# Use jq directly: bashio::config returns the array's JSON in a form that
# downstream jq parses inconsistently in some HA supervisor versions.
plugins=$(jq -r '.plugins // [] | .[]' "${OPTIONS}" 2>/dev/null || true)

if [ -z "${plugins}" ]; then
  bashio::log.info "No plugins declared in addon config; skipping installer."
  exit 0
fi

count=$(printf '%s\n' "${plugins}" | grep -cv '^$')
bashio::log.info "Installing ${count} declared plugin(s)..."

cd "${EP_DIR}"
while IFS= read -r plugin; do
  [ -z "${plugin}" ] && continue
  if [ -d "${EP_DIR}/node_modules/${plugin}" ]; then
    bashio::log.info "  ${plugin}: already installed, skipping"
    continue
  fi
  bashio::log.info "  ${plugin}: installing..."
  if pnpm run plugins i "${plugin}"; then
    bashio::log.info "  ${plugin}: OK"
  else
    bashio::log.warning "  ${plugin}: install failed (check the npm package name); continuing"
  fi
done <<EOF
${plugins}
EOF

bashio::log.info "Plugin install complete."
