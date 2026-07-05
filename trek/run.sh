#!/usr/bin/env sh
set -e

OPTIONS_FILE=/data/options.json
NGINX_CONF=/etc/nginx/conf.d/default.conf
BACKEND_PORT=3001
FRONTEND_PORT=3000
INDEX_HTML=/app/server/public/index.html
ASSETS_DIR=/app/server/public/assets

patch_static_paths() {
    if [ -f "${INDEX_HTML}" ]; then
        # Convert root-absolute frontend references to relative paths so
        # Home Assistant ingress does not send requests to HA core endpoints.
        sed -i 's#src="/assets/#src="./assets/#g' "${INDEX_HTML}"
        sed -i 's#href="/assets/#href="./assets/#g' "${INDEX_HTML}"
        sed -i 's#src="/theme-boot.js"#src="./theme-boot.js"#g' "${INDEX_HTML}"
        sed -i 's#src="/registerSW.js"#src="./registerSW.js"#g' "${INDEX_HTML}"
        sed -i 's#href="/manifest.webmanifest"#href="./manifest.webmanifest"#g' "${INDEX_HTML}"
    fi

    if [ -d "${ASSETS_DIR}" ]; then
        # Patch built CSS/JS bundles that still contain root-absolute paths.
        find "${ASSETS_DIR}" -type f -name '*.css' -exec sed -i 's#url(/assets/#url(./assets/#g' {} \;
        find "${ASSETS_DIR}" -type f -name '*.js' -exec sed -i 's#"/login#"./login#g' {} \;
        find "${ASSETS_DIR}" -type f -name '*.js' -exec sed -i "s#'/login#'./login#g" {} \;
        find "${ASSETS_DIR}" -type f -name '*.js' -exec sed -i 's#"/assets/#"./assets/#g' {} \;
        find "${ASSETS_DIR}" -type f -name '*.js' -exec sed -i "s#'/assets/#'./assets/#g" {} \;
        find "${ASSETS_DIR}" -type f -name '*.js' -exec sed -i 's#"/theme-boot.js"#"./theme-boot.js"#g' {} \;
        find "${ASSETS_DIR}" -type f -name '*.js' -exec sed -i 's#"/registerSW.js"#"./registerSW.js"#g' {} \;
    fi
}

write_nginx_config() {
    cat > "${NGINX_CONF}" <<EOF
map \$request_uri \$ha_ingress_prefix {
    ~^/api/hassio_ingress/([^/]+)/ /api/hassio_ingress/\$1;
    default "";
}

map \$http_upgrade \$connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen ${FRONTEND_PORT};
    server_name _;

    client_max_body_size 500m;

    # Avoid noisy browser policy warnings on local non-HTTPS origins.
    proxy_hide_header Cross-Origin-Opener-Policy;
    proxy_hide_header Origin-Agent-Cluster;
    proxy_hide_header Cross-Origin-Embedder-Policy;

    location ~ ^/api/hassio_ingress/[^/]+/(.*)$ {
        rewrite ^/api/hassio_ingress/[^/]+/(.*)$ /\$1 break;
        proxy_pass http://127.0.0.1:${BACKEND_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Prefix \$ha_ingress_prefix;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_read_timeout 86400;
        proxy_redirect ~^(/.*)$ \$ha_ingress_prefix\$1;

        # Disable compressed upstream responses so sub_filter can rewrite paths.
        proxy_set_header Accept-Encoding "";
        sub_filter_once off;
        sub_filter_types text/html text/css application/javascript application/json;

        # Keep browser requests under ingress prefix.
        sub_filter '"/assets/' '"\$ha_ingress_prefix/assets/';
        sub_filter "'/assets/" "'\$ha_ingress_prefix/assets/";
        sub_filter '"/api/' '"\$ha_ingress_prefix/api/';
        sub_filter "'/api/" "'\$ha_ingress_prefix/api/";
        sub_filter '"/ws"' '"\$ha_ingress_prefix/ws"';
        sub_filter '"/login' '"\$ha_ingress_prefix/login';
        sub_filter '"/registerSW.js"' '"\$ha_ingress_prefix/registerSW.js"';
        sub_filter '"/theme-boot.js"' '"\$ha_ingress_prefix/theme-boot.js"';
        sub_filter '"/manifest.webmanifest"' '"\$ha_ingress_prefix/manifest.webmanifest"';
    }

    location / {
        proxy_pass http://127.0.0.1:${BACKEND_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_read_timeout 86400;
    }
}
EOF
}

start_backend() {
    cd /app/server
    gosu node node --require tsconfig-paths/register dist/index.js &
    BACKEND_PID=$!
}

cleanup() {
    if [ -n "${BACKEND_PID:-}" ]; then
        kill "${BACKEND_PID}" 2>/dev/null || true
    fi
}

trap cleanup INT TERM EXIT

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
export PORT=${BACKEND_PORT}

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

write_nginx_config
patch_static_paths
start_backend
exec nginx -g 'daemon off;'
