# Changelog

## 3.1.15

- Set `CI=true` in the container env so `pnpm run plugins i` doesn't
  bail with `ERR_PNPM_ABORTED_REMOVE_MODULES_DIR_NO_TTY`. The plugin
  installer pnpm uses internally calls `pnpm install --production`
  which tries to purge `node_modules` and prompts without a TTY; the
  `CI=true` hint flips that to non-interactive mode. Same root cause
  as 3.1.2's `pnpm run prod` fix — just hit on a different code path.

## 3.1.14

- Plugin installer rewrite: drop `set -e` and `bashio::log.*` from
  the script. One plugin failing now logs a warning and continues
  instead of bailing the cont-init script with exit 5 and halting
  the whole container.

## 3.1.13

- Fix plugin installer: switch from `bashio::config` (which returned
  the array in a form jq couldn't reparse on some HA supervisor
  builds) to reading `/data/options.json` directly via jq.
  Symptom was `jq: parse error: Invalid numeric literal at line 2,
  column 0` from `20-plugins.sh` and the container halting on boot.
- Treat exit code 143 (SIGTERM, graceful shutdown) as normal in the
  `finish` scripts for both `etherpad` and `etherpad-proxy` services,
  so a clean stop during an addon update no longer logs as a crash.

## 3.1.12

- Reorder the `plugins:` option above the SSL block so it doesn't
  read as a sub-option of "Enable Direct HTTPS" in the HA UI. HA's
  add-on schema has no section-header concept, so positioning is the
  only visual separation.

## 3.1.11

- New `plugins:` addon option — declarative list of Etherpad plugin
  npm packages (e.g. `ep_headings2`) installed on startup. Entries
  not yet present are installed via `pnpm run plugins i <name>`;
  already-installed ones are skipped, so reboots are fast. Survives
  add-on upgrades because the list lives in HA config, not the
  container fs. The in-app `/admin/plugins` UI still works for
  ad-hoc installs (but those are wiped on add-on update).

## 3.1.10

- Make the new `services.d/etherpad-proxy/{run,finish}` scripts
  executable (committed as 0644 in 3.1.8/9; s6 silently failed to
  start the service which then halted the whole container with a
  misleading `s6-overlay-suexec: Permission denied` shutdown error).

## 3.1.9

- Drop the bundled AppArmor profile — it didn't allow
  `s6-overlay-suexec` at `/package/admin/...`, so the addon failed to
  boot with `Permission denied` on startup. Will re-introduce a
  profile in a later release with paths verified against the HA
  base's actual s6 layout.

## 3.1.8

- Fix HA ingress when `ssl: true`. Previously enabling SSL made
  Etherpad listen HTTPS-only on 9001, but HA's ingress proxy connects
  HTTP to the backend — so the sidebar / Open Web UI broke.
  Decoupled internal listener from public port:

    * Etherpad now always listens plain HTTP on 9002.
    * `ingress_port` is 9002, so HA ingress always speaks HTTP to the
      backend — works regardless of TLS state.
    * A `socat` front-man owns port 9001 (the public-facing one) and
      terminates TLS when `ssl: true`, or plain-TCP forwards when off.

- HEALTHCHECK probes Etherpad directly on 9002 so it stays green even
  if socat is mid-restart.

## 3.1.7

- Revert the "copy node + pnpm from upstream" diet from 3.1.6 — the
  copied binary tree was *larger* than installing fresh via `apk` +
  `npm install -g pnpm`, so net image size went up by ~40 MB. Back to
  apk-installed nodejs/npm, with `npm cache clean` to keep what we
  can. Real diet pass deferred until there's something material to
  prune (most of the size is Etherpad's own node_modules, which is
  hard to slim without breaking plugin migration).

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
