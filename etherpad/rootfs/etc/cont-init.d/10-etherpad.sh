#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: Etherpad
# Render a shell env file from /data/options.json so Etherpad's built-in
# ${ENV_VAR:default} substitution in settings.json picks up user config.
# ==============================================================================
set -e

# `jq -R` reads each *line* of its input as a separate string, so any multi-line
# option value emitted one shell-quoted string per line. Every line after the
# first then parsed as a stray command when the env file was sourced, and the
# add-on died with exit 127 — which the stock multi-line `default_pad_text` hit
# on a default install. `-Rs` slurps the whole input into a single string; the
# `sub` drops the one trailing newline bashio appends so values round-trip
# unchanged.
sh_quote() { jq -Rsr 'sub("\n$"; "") | @sh'; }

ENV_FILE=/etc/etherpad/env
mkdir -p "$(dirname "${ENV_FILE}")"

{
  echo "export TITLE=$(bashio::config 'title' | sh_quote)"
  echo "export REQUIRE_AUTHENTICATION=$(bashio::config 'require_authentication')"
  echo "export TRUST_PROXY=$(bashio::config 'trust_proxy')"
  echo "export LOGLEVEL=$(bashio::config 'log_level')"
  echo "export DEFAULT_PAD_TEXT=$(bashio::config 'default_pad_text' | sh_quote)"

  # Force the legacy users.admin.password / users.user.password auth path
  # instead of the upstream Docker default of `sso`. SSO needs an external
  # OIDC server most HA users don't run; with the default, the HA-side
  # admin_password / user_password fields silently did nothing.
  echo "export AUTHENTICATION_METHOD=apikey"

  admin_pw=$(bashio::config 'admin_password')
  if bashio::var.has_value "${admin_pw}"; then
    echo "export ADMIN_PASSWORD=$(printf '%s' "${admin_pw}" | sh_quote)"
  else
    echo "export ADMIN_PASSWORD=null"
  fi

  user_pw=$(bashio::config 'user_password')
  if bashio::var.has_value "${user_pw}"; then
    echo "export USER_PASSWORD=$(printf '%s' "${user_pw}" | sh_quote)"
  else
    echo "export USER_PASSWORD=null"
  fi

  db_type=$(bashio::config 'db_type')
  echo "export DB_TYPE=${db_type}"
  case "${db_type}" in
    sqlite)
      # Default — ACID, single file, survives restarts under /data.
      echo "export DB_FILENAME=/data/etherpad.db"
      ;;
    dirty)
      # Opt-in only; the upstream template warns dirty is dev-only.
      echo "export DB_FILENAME=/data/dirty.db"
      ;;
    *)
      echo "export DB_HOST=$(bashio::config 'db_host')"
      echo "export DB_PORT=$(bashio::config 'db_port')"
      echo "export DB_NAME=$(bashio::config 'db_name')"
      echo "export DB_USER=$(bashio::config 'db_user')"
      echo "export DB_PASS=$(bashio::config 'db_password' | sh_quote)"
      ;;
  esac

  # Etherpad ALWAYS listens plain HTTP on 9002 (the upstream-image setting
  # default of 9001 is wrong for our front-man pattern below). HA's ingress
  # proxy connects to this port; the socat front-man re-exposes it as 9001
  # (with optional TLS) for direct LAN/WAN access.
  echo "export PORT=9002"
  echo "export IP=0.0.0.0"

  # SSL: render the socat invocation for /etc/etherpad/proxy. When `ssl: true`
  # we terminate TLS using HA's mounted /ssl/ certs; otherwise we plain-TCP
  # forward. The front-man is always present so ingress_port (9002) and
  # public port (9001) stay decoupled regardless of TLS state.
  if bashio::config.true 'ssl'; then
    certfile=$(bashio::config 'certfile')
    keyfile=$(bashio::config 'keyfile')
    echo "export PROXY_ARGS=\"OPENSSL-LISTEN:9001,reuseaddr,fork,verify=0,cert=/ssl/${certfile},key=/ssl/${keyfile} TCP:127.0.0.1:9002\""
  else
    echo "export PROXY_ARGS=\"TCP-LISTEN:9001,reuseaddr,fork TCP:127.0.0.1:9002\""
  fi
} > "${ENV_FILE}"

chmod 0600 "${ENV_FILE}"
bashio::log.info "Etherpad configuration rendered to ${ENV_FILE}"
