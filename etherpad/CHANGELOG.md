# Changelog

## 3.1.3

- Enable HA supervisor watchdog (`tcp://[HOST]:[PORT:9001]`). If
  Etherpad stops responding the supervisor will restart the add-on.
  "Show in sidebar" and "Auto update" remain user-side toggles that
  HA doesn't let the addon author default on.

## 3.1.2

- Set `init: false`. HA's default (`init: true`) makes docker put tini
  at PID 1, which fights s6-overlay's "I must be PID 1" assumption and
  bails with `s6-overlay-suexec: fatal: can only run as pid 1`. Every
  HA addon built on the home-assistant base image needs this.

## 3.1.1

- Drop `db_host`/`db_port`/`db_name`/`db_user`/`db_password` defaults
  from `options`. `db_port: 0` violated the `port?` schema (must be
  1–65535), which blocked **Save** in the HA UI even when leaving
  `db_type: sqlite`. Those fields are only relevant for `mysql`/
  `postgres` and the schema still accepts them when provided.

## 3.1.0

- Track upstream Etherpad 3.1.0 release.

## 3.0.0 (initial)

- Initial Home Assistant add-on wrapping the upstream
  `etherpad/etherpad:3.0.0` Docker image.
- Ingress support (requires `trust_proxy: true`).
- Persistent sqlite DB under `/data/etherpad.db` (ACID by default;
  `dirty` remains selectable for dev use).
- Exposes `title`, `require_authentication`, `admin_password`,
  `default_pad_text`, and DB backend selection as HA options.
