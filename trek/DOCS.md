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
| `force_https` | Enable only behind a TLS-terminating reverse proxy. Enforces secure cookies and HTTPS redirects. | `false` |
| `trust_proxy` | Number of trusted proxy hops in front of TREK (usually `1`). | `1` |
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

Release notes are available in [CHANGELOG.md](CHANGELOG.md) and on
[GitHub Releases](https://github.com/stuartp44/trekhomeassistant/releases).

## Accessing TREK

- **Via HA sidebar** — click Open Web UI (uses Home Assistant ingress).
- **Direct URL fallback** — `http://<ha-host>:3000`.

> **Important:** This add-on runs TREK behind an internal nginx reverse proxy
> to handle Home Assistant ingress path translation and redirects.

> **WebSocket note:** Real-time sync uses WebSockets on `/ws` and works over
> ingress and direct connection.

## Reverse proxy (optional)

If you want to expose TREK on a custom domain with TLS, place a reverse proxy
in front of port `3000`. Set `app_url` to the public URL and ensure the proxy
forwards WebSocket upgrades on `/ws`.

Nginx example (matching upstream TREK):

```nginx
server {
	listen 80;
	server_name trek.yourdomain.com;
	return 301 https://$host$request_uri;
}

server {
	listen 443 ssl http2;
	server_name trek.yourdomain.com;

	ssl_certificate     /etc/ssl/fullchain.pem;
	ssl_certificate_key /etc/ssl/privkey.pem;

	# 500 MB covers backup-restore uploads (capped at 500 MB server-side).
	client_max_body_size 500m;

	location / {
		proxy_pass http://localhost:3000;
		proxy_http_version 1.1;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
	}

	location /ws {
		proxy_pass http://localhost:3000;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection "upgrade";
		proxy_set_header Host $host;
		proxy_read_timeout 86400;
	}
}
```

See the [TREK README](https://github.com/mauriceboe/TREK#reverse-proxy) for
additional proxy variants (for example Caddy).

For a native-like Home Assistant experience with HTTPS:

1. Keep this add-on on direct Web UI mode.
2. Put a local reverse proxy in front of TREK (`https://trek.<your-lan-domain>`).
3. Set `app_url` to that HTTPS URL.
4. Set `trust_proxy` to `1` (or your proxy hop count).
5. Set `force_https` to `true` only when TLS termination is active.

## License

- Add-on wrapper repository license: MIT
- Upstream TREK license: [AGPL-3.0](https://github.com/mauriceboe/TREK/blob/main/LICENSE)

This add-on wrapper is maintained separately and is not affiliated with the TREK project.
