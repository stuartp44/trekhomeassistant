#!/usr/bin/env sh
set -e

OPTIONS_FILE=/data/options.json
NGINX_CONF=/etc/nginx/conf.d/default.conf
BACKEND_PORT=3001
FRONTEND_PORT=3000
INDEX_HTML=/app/server/public/index.html
ASSETS_DIR=/app/server/public/assets

patch_static_paths() {
    echo "[run.sh] Applying ingress static-path patch"

    # TREK image layout can vary by version; patch any discovered public dir.
    CANDIDATE_PUBLIC_DIRS=""

    for d in /app/server/public /app/public /app/dist/public; do
        if [ -d "$d" ]; then
            CANDIDATE_PUBLIC_DIRS="$CANDIDATE_PUBLIC_DIRS $d"
        fi
    done

    if [ -d /app ]; then
        discovered=$(find /app -type f -name index.html 2>/dev/null | grep '/public/index.html$' | sed 's#/index.html$##' | sort -u || true)
        if [ -n "$discovered" ]; then
            CANDIDATE_PUBLIC_DIRS="$CANDIDATE_PUBLIC_DIRS $discovered"
        fi
    fi

    if [ -z "$CANDIDATE_PUBLIC_DIRS" ]; then
        echo "[run.sh] No public directories found for static patch"
        return
    fi

    for public_dir in $(printf '%s\n' $CANDIDATE_PUBLIC_DIRS | sort -u); do
        index_html="$public_dir/index.html"
        assets_dir="$public_dir/assets"

        if [ -f "$index_html" ]; then
            echo "[run.sh] Patching index.html in $public_dir"
            # Convert root-absolute frontend references to relative paths so
            # Home Assistant ingress does not send requests to HA core endpoints.
            sed -i 's#src="/assets/#src="./assets/#g' "$index_html"
            sed -i 's#href="/assets/#href="./assets/#g' "$index_html"
            sed -i 's#src="/theme-boot.js"#src="./theme-boot.js"#g' "$index_html"
            sed -i 's#src="/registerSW.js"#src="./registerSW.js"#g' "$index_html"
            sed -i 's#href="/manifest.webmanifest"#href="./manifest.webmanifest"#g' "$index_html"
        fi

        if [ -d "$assets_dir" ]; then
            echo "[run.sh] Patching bundled assets in $assets_dir"
            # Patch built CSS/JS bundles that still contain root-absolute paths.
            find "$assets_dir" -type f -name '*.css' -exec sed -i 's#url(/assets/#url(./assets/#g' {} \;
            find "$assets_dir" -type f -name '*.css' -exec sed -i 's#url(/logo-light.svg)#url(./logo-light.svg)#g' {} \;
            find "$assets_dir" -type f -name '*.css' -exec sed -i 's#url(/logo-dark.svg)#url(./logo-dark.svg)#g' {} \;
            find "$assets_dir" -type f -name '*.css' -exec sed -i 's#url(/icons/#url(./icons/#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/login#"./login#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i "s#'/login#'./login#g" {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/api"#"./api"#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i "s#'/api'#'./api'#g" {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/assets/#"./assets/#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i "s#'/assets/#'./assets/#g" {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/assets"#"./assets"#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i "s#'/assets'#'./assets'#g" {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/icons/#"./icons/#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i "s#'/icons/#'./icons/#g" {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/api/#"./api/#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i "s#'/api/#'./api/#g" {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/ws"#"./ws"#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i "s#'/ws'#'./ws'#g" {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/logo-light.svg"#"./logo-light.svg"#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/logo-dark.svg"#"./logo-dark.svg"#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/theme-boot.js"#"./theme-boot.js"#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/registerSW.js"#"./registerSW.js"#g' {} \;
        fi
    done
}

write_nginx_config() {
    cat > "${NGINX_CONF}" <<EOF
map \$request_uri \$ha_ingress_prefix {
    ~^/api/hassio_ingress/([^/]+)/ /api/hassio_ingress/\$1;
    default "";
}

map \$http_x_ingress_path \$effective_ingress_prefix {
    default \$http_x_ingress_path;
    "" \$ha_ingress_prefix;
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
        proxy_set_header X-Forwarded-Prefix \$effective_ingress_prefix;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_read_timeout 86400;
        proxy_redirect ~^(/.*)$ \$effective_ingress_prefix\$1;

        # Disable compressed upstream responses so sub_filter can rewrite paths.
        proxy_set_header Accept-Encoding "";
        sub_filter_once off;
        sub_filter_types text/html text/css application/javascript application/json;

        # Keep browser requests under ingress prefix.
        sub_filter '"/assets/' '"\$effective_ingress_prefix/assets/';
        sub_filter "'/assets/" "'\$effective_ingress_prefix/assets/";
        sub_filter '"/api/' '"\$effective_ingress_prefix/api/';
        sub_filter "'/api/" "'\$effective_ingress_prefix/api/";
        sub_filter '"/ws"' '"\$effective_ingress_prefix/ws"';
        sub_filter '"/login' '"\$effective_ingress_prefix/login';
        sub_filter '"/registerSW.js"' '"\$effective_ingress_prefix/registerSW.js"';
        sub_filter '"/theme-boot.js"' '"\$effective_ingress_prefix/theme-boot.js"';
        sub_filter '"/manifest.webmanifest"' '"\$effective_ingress_prefix/manifest.webmanifest"';
        sub_filter '"/logo-light.svg"' '"\$effective_ingress_prefix/logo-light.svg"';
        sub_filter '"/logo-dark.svg"' '"\$effective_ingress_prefix/logo-dark.svg"';
        sub_filter '"/icons/' '"\$effective_ingress_prefix/icons/';
        sub_filter "'/icons/" "'\$effective_ingress_prefix/icons/";
    }

    location / {
        proxy_pass http://127.0.0.1:${BACKEND_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Prefix \$effective_ingress_prefix;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_read_timeout 86400;
        proxy_redirect ~^(/.*)$ \$effective_ingress_prefix\$1;

        # HA may strip ingress prefix before sending request to the add-on.
        # Keep response payload URLs anchored to ingress prefix regardless.
        proxy_set_header Accept-Encoding "";
        sub_filter_once off;
        sub_filter_types text/html text/css application/javascript application/json;
        sub_filter '"/assets/' '"\$effective_ingress_prefix/assets/';
        sub_filter "'/assets/" "'\$effective_ingress_prefix/assets/";
        sub_filter '"/api/' '"\$effective_ingress_prefix/api/';
        sub_filter "'/api/" "'\$effective_ingress_prefix/api/";
        sub_filter '"/ws"' '"\$effective_ingress_prefix/ws"';
        sub_filter '"/login' '"\$effective_ingress_prefix/login';
        sub_filter '"/registerSW.js"' '"\$effective_ingress_prefix/registerSW.js"';
        sub_filter '"/theme-boot.js"' '"\$effective_ingress_prefix/theme-boot.js"';
        sub_filter '"/manifest.webmanifest"' '"\$effective_ingress_prefix/manifest.webmanifest"';
        sub_filter '"/logo-light.svg"' '"\$effective_ingress_prefix/logo-light.svg"';
        sub_filter '"/logo-dark.svg"' '"\$effective_ingress_prefix/logo-dark.svg"';
        sub_filter '"/icons/' '"\$effective_ingress_prefix/icons/';
        sub_filter "'/icons/" "'\$effective_ingress_prefix/icons/";
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
