#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: Etherpad
# Write the `settings_json` option to Etherpad's credentials.json.
#
# Etherpad reads credentials.json after settings.json and merges it on top
# (Settings.ts storeSettings): any top-level key works, core settings and
# plugin `ep_*` blocks alike. Object values are merged one level deep with the
# existing value, everything else is replaced. ${ENV_VAR} substitution applies
# too.
#
# Etherpad exits on a credentials.json it can't parse, which would put the
# add-on in a crash loop, so the JSON is validated here first. Invalid JSON is
# logged and dropped, and Etherpad boots with the defaults.
#
# The contents may hold API keys, so they are never logged.
# ==============================================================================

# bashio turns on errexit/pipefail; a failed jq check must not stop the boot.
set +e +o pipefail

CREDENTIALS=/opt/etherpad-lite/credentials.json
OPTIONS=/data/options.json

# A stale file from an earlier boot must never outlive the option.
if ! rm -f "${CREDENTIALS}"; then
  bashio::log.error "Could not remove an old ${CREDENTIALS}; Etherpad may start with stale settings."
fi

if [ ! -f "${OPTIONS}" ]; then
  exit 0
fi

settings_json=$(jq -r '.settings_json // ""' "${OPTIONS}" 2>/dev/null)

# Whitespace only counts as empty.
if [ -z "${settings_json//[[:space:]]/}" ]; then
  bashio::log.info "settings_json is empty; using the add-on defaults."
  exit 0
fi

# Exactly one JSON object. jq's error text quotes the offending input, so it
# is discarded and only the line/column is reported.
if ! printf '%s' "${settings_json}" | jq -se 'length == 1 and (.[0] | type == "object")' >/dev/null 2>&1; then
  where=$(printf '%s' "${settings_json}" | jq -s . 2>&1 >/dev/null | grep -o 'at line [0-9]*, column [0-9]*' | head -n1)
  bashio::log.error "settings_json is not a valid JSON object${where:+ (${where})}."
  bashio::log.error "Ignoring settings_json and starting Etherpad with the add-on defaults."
  exit 0
fi

# Write to a temp file and move it into place only once it is complete, so a
# failed write can never leave a partial credentials.json for Etherpad to
# choke on.
tmp="${CREDENTIALS}.tmp.$$"
if ( umask 077 && printf '%s' "${settings_json}" | jq . > "${tmp}" ) && mv -f "${tmp}" "${CREDENTIALS}"; then
  keys=$(jq -r 'keys_unsorted | join(", ")' "${CREDENTIALS}")
  bashio::log.info "settings_json applied via ${CREDENTIALS} (top-level keys: ${keys})."
else
  rm -f "${tmp}" "${CREDENTIALS}"
  bashio::log.error "Could not write ${CREDENTIALS}; starting Etherpad with the add-on defaults."
fi
exit 0
