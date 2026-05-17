# Home Assistant Add-on: Etherpad

Realtime collaborative document editor, packaged as a one-click Home
Assistant add-on.

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**.
2. Click the three-dot menu (top right) → **Repositories**.
3. Add this repository URL:
   `https://github.com/ether/home-assistant-addon-etherpad`
4. Find **Etherpad** in the store, click **Install**, then **Start**.
5. Use **Open Web UI** to launch Etherpad through Home Assistant ingress,
   or browse directly to `http://<ha-host>:9001`.

## Configuration

| Option                  | Description                                                           |
| ----------------------- | --------------------------------------------------------------------- |
| `title`                 | Instance name shown in the browser tab.                               |
| `require_authentication`| If `true`, all pads require login.                                    |
| `admin_password`        | Password for the built-in `admin` user (access to `/admin`).          |
| `user_password`         | Password for the built-in `user` account.                             |
| `default_pad_text`      | Text inserted into every newly-created pad.                           |
| `db_type`               | One of `sqlite` (default, file-backed, ACID), `mysql`, `postgres`, `dirty`. |
| `db_host`/`db_port`/... | Used only when `db_type` is `mysql` or `postgres`.                    |
| `trust_proxy`           | Leave `true` so Home Assistant ingress works correctly.               |
| `log_level`             | Etherpad log verbosity.                                               |

### Data persistence

When `db_type` is `sqlite` (the default), pads are stored in
`/data/etherpad.db` inside the add-on's persistent volume. The
`dirty` backend (opt-in) writes to `/data/dirty.db` but is flagged
dev-only by the upstream settings template. `mysql`/`postgres` expect
an external database you operate yourself.

### Ingress

This add-on is ingress-enabled: Home Assistant proxies requests to
Etherpad behind authentication, and Etherpad's `trustProxy` setting
ensures cookies and client IPs work correctly. Keep `trust_proxy` set
to `true` for ingress to function.

If ingress misbehaves (Etherpad does not currently support a configurable
URL base path), disable it by editing `config.yaml` and use the direct
port 9001 instead.

## Recommended one-time toggles

After install, on the addon's **Info** tab, turn on:

- **Show in sidebar** — gives you a one-click shortcut.
- **Watchdog** — already pre-enabled via `config.yaml`; HA will
  TCP-probe the addon on port 9001 and restart on failure.
- **Auto update** — opt-in for releases of this add-on.

HA doesn't let an addon author force these on for new installs.

## Security notes

- **Admin passwords are stored in plaintext** in Home Assistant's
  supervisor database (the `options.json` that the add-on reads). For
  stronger secret handling, install the `ep_hash_auth` Etherpad plugin
  and supply a bcrypt hash via a hand-edited `settings.json` (advanced).
- The direct port (9001) bypasses Home Assistant authentication.
  Firewall it off, or leave only ingress enabled if you care.

## Links

- Etherpad: <https://etherpad.org>
- Upstream repo: <https://github.com/ether/etherpad>
- Docker image: <https://hub.docker.com/r/etherpad/etherpad>
- Report bugs: <https://github.com/ether/etherpad/issues>
- HA add-on docs: <https://developers.home-assistant.io/docs/add-ons/>
