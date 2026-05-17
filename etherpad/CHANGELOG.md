# Changelog

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
