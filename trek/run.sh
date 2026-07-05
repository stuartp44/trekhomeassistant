#!/usr/bin/env sh
set -e

OPTIONS_FILE=/data/options.json

# ── Persistent storage ────────────────────────────────────────────────────
# The Home Assistant Supervisor mounts the add-on's persistent storage at /data.
# TREK expects its data at /app/data and uploads at /app/uploads.
# We create the required sub-directories under /data on first run, then replace
# the image-built empty directories with symlinks so TREK writes to persistent
# storage across restarts and upgrades.

mkdir -p \
    /data/trek_data/logs \
    /data/uploads/files \
    /data/uploads/covers \
    /data/uploads/avatars \
    /data/uploads/photos

# rm -rf on a symlink removes the symlink itself (not the target), so this is
# idempotent whether /app/data is a fresh directory or a leftover symlink.
rm -rf /app/data /app/uploads
ln -sf /data/trek_data /app/data
ln -sf /data/uploads /app/uploads

chown -R node:node /data/trek_data /data/uploads 2>/dev/null || true

# ── Configuration from HA add-on options ─────────────────────────────────
export NODE_ENV=production
export PORT=3000

ENCRYPTION_KEY=$(jq --raw-output '.encryption_key // ""' "${OPTIONS_FILE}")
[ -n "${ENCRYPTION_KEY}" ] && export ENCRYPTION_KEY

export ADMIN_EMAIL
ADMIN_EMAIL=$(jq --raw-output '.admin_email // "admin@trek.local"' "${OPTIONS_FILE}")

ADMIN_PASSWORD=$(jq --raw-output '.admin_password // ""' "${OPTIONS_FILE}")
[ -n "${ADMIN_PASSWORD}" ] && export ADMIN_PASSWORD

export LOG_LEVEL
LOG_LEVEL=$(jq --raw-output '.log_level // "info"' "${OPTIONS_FILE}")

export TZ
TZ=$(jq --raw-output '.tz // "UTC"' "${OPTIONS_FILE}")

APP_URL=$(jq --raw-output '.app_url // ""' "${OPTIONS_FILE}")
[ -n "${APP_URL}" ] && export APP_URL

ALLOWED_ORIGINS=$(jq --raw-output '.allowed_origins // ""' "${OPTIONS_FILE}")
[ -n "${ALLOWED_ORIGINS}" ] && export ALLOWED_ORIGINS

# Optional OIDC / SSO settings
OIDC_ISSUER=$(jq --raw-output '.oidc_issuer // ""' "${OPTIONS_FILE}")
if [ -n "${OIDC_ISSUER}" ]; then
    export OIDC_ISSUER

    OIDC_CLIENT_ID=$(jq --raw-output '.oidc_client_id // ""' "${OPTIONS_FILE}")
    [ -n "${OIDC_CLIENT_ID}" ] && export OIDC_CLIENT_ID

    OIDC_CLIENT_SECRET=$(jq --raw-output '.oidc_client_secret // ""' "${OPTIONS_FILE}")
    [ -n "${OIDC_CLIENT_SECRET}" ] && export OIDC_CLIENT_SECRET

    export OIDC_DISPLAY_NAME
    OIDC_DISPLAY_NAME=$(jq --raw-output '.oidc_display_name // "SSO"' "${OPTIONS_FILE}")
fi

# ── Start TREK ────────────────────────────────────────────────────────────
# Must cd into /app/server so tsconfig-paths/register can resolve tsconfig.json
# and ../node_modules. gosu drops privileges from root to the node user.
cd /app/server
exec gosu node node --require tsconfig-paths/register dist/index.js
