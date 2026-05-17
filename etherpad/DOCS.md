# Home Assistant Add-on: Etherpad

Real-time collaborative document editor, packaged as a one-click Home
Assistant add-on.

## How it works

This add-on wraps the official [`etherpad/etherpad`](https://hub.docker.com/r/etherpad/etherpad)
Docker image with the Home Assistant supervisor scaffolding
(s6-overlay, bashio, ingress, options schema). Your pads live in HA's
persistent volume so they survive restarts, backups, and add-on
updates.

## Installation

1. **Settings → Add-ons → Add-on Store**.
2. **⋮ (top right) → Repositories.**
3. Add `https://github.com/ether/home-assistant-addon-etherpad`.
4. Refresh the store, find **Etherpad**, click **Install**.

## First run

1. **Configuration tab** — change `Admin Password` if you plan to use
   the admin UI; otherwise the defaults are fine for LAN use.
2. **Save**, then **Info tab → Start.**
3. Open Etherpad through one of:
   - **Open Web UI** (via Home Assistant ingress, HTTPS reusing your
     HA frontend's certificate).
   - **Direct port**: `http://<ha-host>:9001` (or `https://` when SSL
     is enabled below).

## SSL / HTTPS

Flip `Enable Direct HTTPS` in the Configuration tab to make Etherpad
serve HTTPS directly on port 9001. HA mounts `/ssl/` read-only inside
the add-on; the defaults look for `fullchain.pem` and `privkey.pem`,
which is the layout produced by the `core_letsencrypt` add-on or any
other HA-managed cert. Override the filenames if you keep your cert
under different names.

If you're happy with HA's ingress (which already serves TLS via your
HA frontend's certificate), leave direct HTTPS off — it's only useful
when you want to expose Etherpad on its own public hostname.

## Data persistence

| Backend | Where it stores pads |
| --- | --- |
| `sqlite` (default) | `/data/etherpad.db` inside the add-on volume. ACID. Survives backups. |
| `dirty` | `/data/dirty.db`. Dev-only — Etherpad upstream warns against production use. |
| `mysql` / `postgres` | External database you operate yourself. Set host/port/name/user/password. |

Home Assistant's built-in **Backup** captures the entire `/data` tree,
so a snapshot covers every pad regardless of backend.

## Recommended one-time toggles

After install, on the add-on's **Info** tab:

- **Show in sidebar** — Etherpad becomes a click in the HA sidebar.
- **Auto update** — HA pulls new add-on releases without prompting
  (the upstream-bump cron in this repo means new Etherpad versions
  land here automatically too).
- **Watchdog** — supervisor restarts the add-on if it stops
  responding (the add-on ships a Docker `HEALTHCHECK` so this just
  works).

The Home Assistant add-on spec doesn't let an add-on author flip
these on for new installs, so flipping them once after install is
unavoidable.

## Reaching Etherpad from outside the LAN

To expose Etherpad publicly:

1. Point a domain at your HA box (e.g. via DuckDNS).
2. Forward TCP `9001` on your router to the HA host.
3. Enable **Direct HTTPS** above so traffic on `:9001` is TLS-encrypted.

Browsers will trust the certificate as long as its SAN covers the
hostname you reach Etherpad with. If you already use Let's Encrypt
for your HA UI, the same `fullchain.pem` works here for free.

## Security notes

- **Admin passwords are plaintext** in HA's supervisor options
  database. For bcrypt-hashed credentials, install the
  [`ep_hash_auth`](https://www.npmjs.com/package/ep_hash_auth) plugin
  from the Etherpad admin UI.
- The direct port (9001) bypasses HA's authentication. If you don't
  intend to expose it externally, firewall it off and use HA ingress
  exclusively.
- The add-on ships with an AppArmor profile that restricts container
  capabilities to what Etherpad actually needs (network + read access
  to `/opt/etherpad-lite`, write to `/data`).

## Troubleshooting

- **"Update failed"** — usually means the new image hasn't finished
  building or publishing to GHCR yet. Wait a minute, ⋮ → Reload, try
  again.
- **Blank Open Web UI** — Etherpad doesn't fully support a
  configurable URL base path. The HA ingress proxy serves a random
  prefix that some legacy bits of Etherpad mis-render. Use the direct
  port instead. (Ingress *does* work when `Enable Direct HTTPS` is
  off — but with it on, the socat front-man terminates TLS for
  port 9001 while ingress still talks plain HTTP to Etherpad on the
  internal 9002 port, so both work simultaneously.)
- **`SSL_ERROR_RX_RECORD_TOO_LONG`** — `ssl` is off but you tried
  HTTPS. Flip the **Enable Direct HTTPS** toggle and restart.
- **Slow startup (~30 s)** — Etherpad scans installed plugins on
  boot. The add-on's `HEALTHCHECK` has a 120 s grace period so this
  won't trip the supervisor watchdog.

## Support

Issues with this add-on: <https://github.com/ether/home-assistant-addon-etherpad/issues>
Upstream Etherpad bugs: <https://github.com/ether/etherpad/issues>
