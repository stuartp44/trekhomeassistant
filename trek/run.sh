#!/usr/bin/env sh
set -e

OPTIONS_FILE=/data/options.json
APP_PORT=3000

# Persistent storage
mkdir -p \
    /data/trek_data/logs \
    /data/uploads/files \
    /data/uploads/covers \
    /data/uploads/avatars \
    /data/uploads/photos

rm -rf /app/data /app/uploads
ln -sf /data/trek_data /app/data
ln -sf /data/uploads /app/uploads

chown -R node:node /data/trek_data /data/uploads 2>/dev/null || true

# Configuration from HA add-on options
export NODE_ENV=production
export PORT=${APP_PORT}

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

FORCE_HTTPS=$(jq --raw-output '.force_https // false' "${OPTIONS_FILE}")
[ "${FORCE_HTTPS}" = "true" ] && export FORCE_HTTPS=true

TRUST_PROXY=$(jq --raw-output '.trust_proxy // 1' "${OPTIONS_FILE}")
[ -n "${TRUST_PROXY}" ] && export TRUST_PROXY

ALLOWED_ORIGINS=$(jq --raw-output '.allowed_origins // ""' "${OPTIONS_FILE}")
[ -n "${ALLOWED_ORIGINS}" ] && export ALLOWED_ORIGINS

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

cd /app/server
exec gosu node node --require tsconfig-paths/register dist/index.js
