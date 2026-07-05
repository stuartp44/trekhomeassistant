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
                ingress_shim="$public_dir/ha-ingress-runtime.js"

                cat > "$ingress_shim" <<'EOF'
(function () {
    function extractBase(pathname) {
        if (!pathname || typeof pathname !== 'string') return '';
        var m = pathname.match(/^(\/api\/hassio_ingress\/[^/]+\/)/);
        if (m) return m[1];
        m = pathname.match(/^(\/hassio_ingress\/[^/]+\/)/);
        if (m) return m[1];
        return '';
    }

    function pathFromUrl(url) {
        try {
            return new URL(url, window.location.origin).pathname || '/';
        } catch (_) {
            return '';
        }
    }

    var base = extractBase(window.location.pathname || '/');

    if (!base && document.currentScript && document.currentScript.src) {
        base = extractBase(pathFromUrl(document.currentScript.src));
    }

    if (!base) {
        var shim = document.querySelector('script[src*="ha-ingress-runtime.js"]');
        if (shim && shim.src) {
            base = extractBase(pathFromUrl(shim.src));
        }
    }

    if (!base) return;

    function rewrite(url) {
        if (typeof url !== 'string') return url;

        if (/^https?:\/\//i.test(url)) {
            try {
                var parsed = new URL(url, window.location.origin);
                if (parsed.origin !== window.location.origin) return url;
                return rewrite(parsed.pathname + (parsed.search || '') + (parsed.hash || ''));
            } catch (_) {
                return url;
            }
        }

        if (!url.startsWith('/') || url.startsWith('//')) return url;
        if (url.startsWith(base)) return url;

        var shouldRewrite =
            url.startsWith('/api') ||
            url.startsWith('/assets') ||
            url.startsWith('/icons') ||
            url === '/theme-boot.js' ||
            url === '/registerSW.js' ||
            url === '/manifest.webmanifest' ||
            url === '/logo-light.svg' ||
            url === '/logo-dark.svg' ||
            url === '/login' ||
            url.startsWith('/login?') ||
            url === '/ws' ||
            url.startsWith('/ws?');

        if (!shouldRewrite) return url;
        return base + url.replace(/^\//, '');
    }

    function patchSetter(proto, prop) {
        if (!proto) return;
        var desc = Object.getOwnPropertyDescriptor(proto, prop);
        if (!desc || !desc.set || !desc.get) return;

        Object.defineProperty(proto, prop, {
            configurable: true,
            enumerable: desc.enumerable,
            get: function () {
                return desc.get.call(this);
            },
            set: function (value) {
                if (typeof value === 'string') value = rewrite(value);
                return desc.set.call(this, value);
            }
        });
    }

    function patchDomWriters() {
        if (window.Element && window.Element.prototype && window.Element.prototype.setAttribute) {
            var _setAttribute = window.Element.prototype.setAttribute;
            window.Element.prototype.setAttribute = function (name, value) {
                if (typeof value === 'string' && (name === 'src' || name === 'href' || name === 'action')) {
                    value = rewrite(value);
                }
                return _setAttribute.call(this, name, value);
            };
        }

        patchSetter(window.HTMLImageElement && window.HTMLImageElement.prototype, 'src');
        patchSetter(window.HTMLScriptElement && window.HTMLScriptElement.prototype, 'src');
        patchSetter(window.HTMLSourceElement && window.HTMLSourceElement.prototype, 'src');
        patchSetter(window.HTMLVideoElement && window.HTMLVideoElement.prototype, 'src');
        patchSetter(window.HTMLAudioElement && window.HTMLAudioElement.prototype, 'src');
        patchSetter(window.HTMLLinkElement && window.HTMLLinkElement.prototype, 'href');
        patchSetter(window.HTMLAnchorElement && window.HTMLAnchorElement.prototype, 'href');
        patchSetter(window.HTMLFormElement && window.HTMLFormElement.prototype, 'action');

        // Catch direct assignments like window.location.href = '/login?...'.
        try {
            patchSetter(Object.getPrototypeOf(window.location), 'href');
        } catch (_) {}
    }

    var _fetch = window.fetch;
    if (typeof _fetch === 'function') {
        window.fetch = function (input, init) {
            if (typeof input === 'string') {
                return _fetch.call(this, rewrite(input), init);
            }
            if (input && input.url && typeof Request === 'function') {
                return _fetch.call(this, new Request(rewrite(input.url), input), init);
            }
            return _fetch.call(this, input, init);
        };
    }

    if (window.XMLHttpRequest && window.XMLHttpRequest.prototype) {
        var _open = window.XMLHttpRequest.prototype.open;
        window.XMLHttpRequest.prototype.open = function (method, url) {
            arguments[1] = rewrite(url);
            return _open.apply(this, arguments);
        };
    }

    if (window.location && window.location.assign && window.location.replace) {
        var _assign = window.location.assign.bind(window.location);
        var _replace = window.location.replace.bind(window.location);

        window.location.assign = function (url) {
            if (typeof url === 'string') url = rewrite(url);
            return _assign(url);
        };

        window.location.replace = function (url) {
            if (typeof url === 'string') url = rewrite(url);
            return _replace(url);
        };

        try {
            var locProto = Object.getPrototypeOf(window.location);
            var hrefDesc = locProto && Object.getOwnPropertyDescriptor(locProto, 'href');
            if (hrefDesc && hrefDesc.get && hrefDesc.set) {
                Object.defineProperty(locProto, 'href', {
                    configurable: true,
                    enumerable: hrefDesc.enumerable,
                    get: function () {
                        return hrefDesc.get.call(this);
                    },
                    set: function (url) {
                        if (typeof url === 'string') url = rewrite(url);
                        return hrefDesc.set.call(this, url);
                    }
                });
            }
        } catch (_) {}
    }

    if (window.history && window.history.pushState && window.history.replaceState) {
        var _pushState = window.history.pushState.bind(window.history);
        var _replaceState = window.history.replaceState.bind(window.history);

        window.history.pushState = function (state, title, url) {
            if (typeof url === 'string') url = rewrite(url);
            return _pushState(state, title, url);
        };

        window.history.replaceState = function (state, title, url) {
            if (typeof url === 'string') url = rewrite(url);
            return _replaceState(state, title, url);
        };
    }

    if (window.open) {
        var _openWindow = window.open.bind(window);
        window.open = function (url, target, features) {
            if (typeof url === 'string') url = rewrite(url);
            return _openWindow(url, target, features);
        };
    }

    document.addEventListener('click', function (ev) {
        var node = ev && ev.target;
        while (node && node !== document && !node.href) node = node.parentNode;
        if (!node || !node.href) return;

        var href = node.getAttribute && node.getAttribute('href');
        if (!href || typeof href !== 'string') return;

        var fixed = rewrite(href);
        if (fixed !== href) {
            ev.preventDefault();
            window.location.assign(fixed);
        }
    }, true);

    document.addEventListener('submit', function (ev) {
        var form = ev && ev.target;
        if (!form || !form.getAttribute || !form.setAttribute) return;
        var action = form.getAttribute('action');
        if (!action || typeof action !== 'string') return;
        var fixed = rewrite(action);
        if (fixed !== action) form.setAttribute('action', fixed);
    }, true);

    patchDomWriters();

    function rewriteDomUrls(root) {
        if (!root || !root.querySelectorAll) return;
        var nodes = root.querySelectorAll('img[src],script[src],source[src],video[src],audio[src],link[href],a[href],form[action]');

        for (var i = 0; i < nodes.length; i++) {
            var el = nodes[i];
            var src = el.getAttribute('src');
            var href = el.getAttribute('href');
            var action = el.getAttribute('action');

            if (src) {
                var fixedSrc = rewrite(src);
                if (fixedSrc !== src) el.setAttribute('src', fixedSrc);
            }

            if (href) {
                var fixedHref = rewrite(href);
                if (fixedHref !== href) el.setAttribute('href', fixedHref);
            }

            if (action) {
                var fixedAction = rewrite(action);
                if (fixedAction !== action) el.setAttribute('action', fixedAction);
            }
        }
    }

    rewriteDomUrls(document);

    if (window.MutationObserver && document && document.documentElement) {
        var mo = new MutationObserver(function (mutations) {
            for (var i = 0; i < mutations.length; i++) {
                var mm = mutations[i];
                if (mm.type === 'attributes' && mm.target && mm.target.parentNode) {
                    rewriteDomUrls(mm.target.parentNode);
                }
                if (mm.addedNodes && mm.addedNodes.length) {
                    for (var j = 0; j < mm.addedNodes.length; j++) {
                        var n = mm.addedNodes[j];
                        if (n && n.nodeType === 1) rewriteDomUrls(n);
                    }
                }
            }
        });

        mo.observe(document.documentElement, {
            subtree: true,
            childList: true,
            attributes: true,
            attributeFilter: ['src', 'href', 'action']
        });
    }

    if (navigator.serviceWorker && navigator.serviceWorker.getRegistrations) {
        navigator.serviceWorker.getRegistrations().then(function (regs) {
            for (var i = 0; i < regs.length; i++) regs[i].unregister();
        }).catch(function () {});
    }
})();
EOF

        if [ -f "$index_html" ]; then
            echo "[run.sh] Patching index.html in $public_dir"
            # Ensure runtime shim loads as early as possible (before app bundle).
            sed -i 's#<script src="\./ha-ingress-runtime.js"></script>##g' "$index_html"
            sed -i 's#<head>#<head>\n  <script src="./ha-ingress-runtime.js"></script>#' "$index_html"
        fi

        if [ -d "$assets_dir" ]; then
            echo "[run.sh] Applying targeted bundled-asset rewrites in $assets_dir"
            # Keep this narrowly scoped to avoid path corruption.
            # Fonts in CSS commonly use url(/assets/<file>), which escapes ingress.
            find "$assets_dir" -type f -name '*.css' -exec sed -i 's#url(/assets/#url(./#g' {} \;

            # Login and logo literals appear in bundled JS as root-absolute paths.
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/login#"./login#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i "s#'/login#'./login#g" {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/logo-light.svg"#"./logo-light.svg"#g' {} \;
            find "$assets_dir" -type f -name '*.js' -exec sed -i 's#"/logo-dark.svg"#"./logo-dark.svg"#g' {} \;
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
