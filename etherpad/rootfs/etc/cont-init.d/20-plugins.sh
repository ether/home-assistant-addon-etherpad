#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: Etherpad
# Install the user's declared plugins on startup. Etherpad's own
# `/admin/plugins` UI still works for ad-hoc installs, but those don't
# survive addon updates (they go into the image filesystem at
# /opt/etherpad-lite/node_modules). This script makes the `plugins:` option
# in the addon config the source of truth: every boot we reinstall anything
# in the list that isn't already present, which survives image rebuilds.
#
# Intentionally NOT using `set -e` or bashio loggers — a single pnpm
# misstep on one plugin shouldn't halt the whole container. Failures are
# logged, the loop continues, the cont-init script always exits 0.
# ==============================================================================

EP_DIR=/opt/etherpad-lite
OPTIONS=/data/options.json

log() { echo "[plugins] $*"; }

if [ ! -f "${OPTIONS}" ]; then
  log "No /data/options.json yet; skipping installer."
  exit 0
fi

plugins=$(jq -r '.plugins // [] | .[]' "${OPTIONS}" 2>/dev/null)

if [ -z "${plugins}" ]; then
  log "No plugins declared in addon config; skipping installer."
  exit 0
fi

log "Installing declared plugin(s):"
printf '%s\n' "${plugins}" | sed 's/^/[plugins]   - /'

# Run Etherpad's plugin CLI with node directly. `pnpm run plugins` makes pnpm
# check the workspace lockfile first, and in the image that check fails with
# ERR_PNPM_OUTDATED_LOCKFILE, so no plugin ever got installed.
cd "${EP_DIR}/bin" || { log "Cannot cd into ${EP_DIR}/bin; aborting."; exit 0; }

# shellcheck disable=SC2034
exit_code=0
while IFS= read -r plugin; do
  [ -z "${plugin}" ] && continue
  # Etherpad installs plugins into src/plugin_packages, not node_modules.
  if [ -d "${EP_DIR}/src/plugin_packages/${plugin}" ]; then
    log "  ${plugin}: already installed, skipping"
    continue
  fi
  log "  ${plugin}: installing..."
  if node --import tsx ./plugins.ts i "${plugin}"; then
    log "  ${plugin}: OK"
  else
    log "  ${plugin}: install failed (check the npm package name); continuing"
  fi
done <<EOF
${plugins}
EOF

log "Plugin install complete."
exit 0
