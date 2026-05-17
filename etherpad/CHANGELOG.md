# Changelog

## 3.1.6

- Polish pass toward HA-official-addon quality:
  - Localized config UI via `translations/en.yaml` (every option now
    has a human-readable name and helper description in the HA UI).
  - In-app `DOCS.md` rendered in HA's Documentation tab.
  - AppArmor profile (`apparmor.txt`) — capabilities + paths trimmed
    to what Etherpad actually needs.
  - `build.yaml` makes the per-arch base image and add-on labels
    explicit (HA convention).
  - Re-enabled Cosign signing on built images.
  - Image diet: dropped `apk add nodejs npm` and the runtime
    `npm install -g pnpm`; the upstream `etherpad/etherpad` image
    already ships node + pnpm and we just copy them over.
  - `backup: hot` + `stage: stable` declared.
  - Fixed the noisy `Unknown Setting: EP_DIR` startup warning by
    keeping `EP_DIR` scoped to the run script instead of the
    container env.

## 3.1.5

- Fix SSL not taking effect with `ssl: true` (browser was getting
  `SSL_ERROR_RX_RECORD_TOO_LONG`). Etherpad's env-var path split
  skips its `EP` root, so the prefix needs two trailing underscores:
  `EP__ssl__key=` not `EP_ssl__key=`. With single-underscore the
  value landed at `settings.EP_ssl.key`, which Etherpad's HTTP
  server ignored.

## 3.1.4

- Optional **direct SSL** on port 9001. Flip `ssl: true` in the addon
  Configuration; HA mounts `/ssl/` read-only and the addon exports
  `EP_ssl__key` / `EP_ssl__cert` so Etherpad listens HTTPS directly.
  Defaults to `fullchain.pem` + `privkey.pem` (the standard HA cert
  layout, e.g. from the `core_letsencrypt` add-on).
- HEALTHCHECK now tries HTTP first then HTTPS so it works regardless
  of `ssl` state.
- Reach the SSL endpoint directly via `https://<ha-host>:9001/`. The
  "Open Web UI" button stays bound to ingress because HA's addon
  linter rejects setting both `webui` and `ingress`.

## 3.1.3

- Add a Docker HEALTHCHECK that curls `/` on port 9001. The HA
  supervisor reads this as the watchdog signal and will auto-restart
  the addon if it stops responding (`120 s` start-period covers
  Etherpad's plugin-migration warmup).
- Add a daily `upstream-bump` workflow that polls Docker Hub for new
  `etherpad/etherpad` releases and auto-commits a version bump,
  so the addon picks up new Etherpad releases without manual edits.
- "Show in sidebar" and "Auto update" remain user-side toggles that
  HA doesn't let the addon author default on; the README points to
  the right place to flip them.

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
