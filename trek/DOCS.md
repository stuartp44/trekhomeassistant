# TREK — Home Assistant Add-on

TREK is a self-hosted, real-time collaborative travel planner. This add-on runs
the official [mauriceboe/trek](https://github.com/mauriceboe/TREK) Docker image
inside your Home Assistant instance, pinned to a specific upstream release.

## Upstream Credit

- Upstream project: [mauriceboe/TREK](https://github.com/mauriceboe/TREK)
- Creator and maintainer: [Maurice Boehm (@mauriceboe)](https://github.com/mauriceboe)
- This add-on is an unofficial packaging wrapper and is not affiliated with the upstream TREK maintainers.

## Features

- **Trip planning** — drag-and-drop planner, interactive map, place search
- **Travel management** — reservations, expenses, packing lists, documents
- **Collaboration** — real-time sync, multi-user trips, chat, polls
- **Mobile PWA** — installable on iOS and Android, offline support
- **AI / MCP** — built-in MCP server with 150+ tools for AI assistants
- **SSO** — OIDC integration (Google, Apple, Authentik, Keycloak, etc.)

## Installation

1. Add this repository to your Home Assistant add-on store.
2. Install the **TREK** add-on.
3. Configure the options (see below).
4. Start the add-on.
5. Open the TREK web interface via the sidebar or on port `3000`.

## First boot

On first boot, TREK seeds an admin account. If you set **Admin Email** and
**Admin Password** in the options, those credentials are used. Otherwise a
random password is printed to the add-on log — check it with
**Supervisor → TREK → Log**.

## Configuration

| Option | Description | Default |
|--------|-------------|---------|
| `encryption_key` | At-rest encryption key for stored secrets. Generate with `openssl rand -hex 32`. Auto-generated if left empty (recommended to set explicitly so you can rotate it). | auto |
| `admin_email` | Email address for the first admin account (first boot only). | `admin@trek.local` |
| `admin_password` | Password for the first admin account. Random if left empty. | random |
| `log_level` | Log verbosity: `info` (user actions) or `debug` (verbose). | `info` |
| `tz` | Timezone for logs and cron jobs, e.g. `Europe/Berlin`. | `UTC` |
| `app_url` | Public base URL of this instance, e.g. `https://trek.example.com`. Required when OIDC is enabled and for email notification links. | — |
| `allowed_origins` | Comma-separated CORS origins. Leave empty for same-origin. | — |
| `oidc_issuer` | OpenID Connect provider URL (leave empty to disable SSO). | — |
| `oidc_client_id` | OIDC client ID. | — |
| `oidc_client_secret` | OIDC client secret. | — |
| `oidc_display_name` | Label on the SSO login button. | `SSO` |

## Data & backups

Persistent data is stored in the add-on's `/data` folder, managed by HA Supervisor:

| Path (inside add-on) | Contents |
|----------------------|----------|
| `/data/trek_data/` | SQLite database, logs, and TREK configuration |
| `/data/uploads/` | User-uploaded files, photos, and documents |

Use the **Admin Panel → Backups** feature inside TREK, or the standard
Home Assistant backup system to protect your data.

## Updating

Update the add-on via **Supervisor → TREK → Update**. Your data is preserved
in the persistent storage volume.

## Accessing TREK

- **Via HA sidebar** — click the TREK panel entry (uses HA Ingress).
- **Direct URL** — `http://<ha-host>:3000` (requires the port to be exposed in
  Network settings).

> **WebSocket note:** Real-time sync uses WebSockets on `/ws`. Both the HA
> Ingress proxy and a direct connection support WebSocket upgrades.

## Reverse proxy (optional)

If you want to expose TREK on a custom domain with TLS, place a reverse proxy
in front of port `3000`. Set `app_url` to the public URL and ensure the proxy
forwards WebSocket upgrades on `/ws`. See the
[TREK README](https://github.com/mauriceboe/TREK#reverse-proxy) for Nginx and
Caddy examples.

## License

- Add-on wrapper repository license: MIT
- Upstream TREK license: [AGPL-3.0](https://github.com/mauriceboe/TREK/blob/main/LICENSE)

This add-on wrapper is maintained separately and is not affiliated with the TREK project.
