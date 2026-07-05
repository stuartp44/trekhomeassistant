#!/usr/bin/env sh
set -e

OPTIONS_FILE=/data/options.json

INDEX_HTML=/app/server/public/index.html

apply_ingress_compat_patch() {
        if [ ! -f "${INDEX_HTML}" ]; then
                return
        fi

        # Make root-absolute static references in index.html relative so they load
        # correctly when Home Assistant serves the app under an ingress subpath.
        sed -i 's#src="/assets/#src="./assets/#g' "${INDEX_HTML}"
        sed -i 's#href="/assets/#href="./assets/#g' "${INDEX_HTML}"
        sed -i 's#src="/theme-boot.js"#src="./theme-boot.js"#g' "${INDEX_HTML}"
        sed -i 's#src="/registerSW.js"#src="./registerSW.js"#g' "${INDEX_HTML}"
        sed -i 's#href="/manifest.webmanifest"#href="./manifest.webmanifest"#g' "${INDEX_HTML}"

        if grep -q 'ha-ingress-compat-shim' "${INDEX_HTML}"; then
                return
        fi

        cat > /tmp/ha-ingress-compat-shim.html <<'EOF'
<script id="ha-ingress-compat-shim">
(function () {
    var p = window.location.pathname || '/';
    var m = p.match(/^(\/api\/hassio_ingress\/[^/]+\/)/);
    var base = m ? m[1] : '/';
    function rewrite(url) {
        if (typeof url !== 'string') return url;

        // Rewrite same-origin absolute URLs (https://host/api/...) as well as
        // root-relative URLs (/api/...) so axios/fetch/xhr all route through
        // Home Assistant ingress.
        if (/^https?:\/\//i.test(url)) {
            try {
                var parsed = new URL(url, window.location.origin);
                if (parsed.origin !== window.location.origin) return url;
                return rewrite(parsed.pathname + (parsed.search || '') + (parsed.hash || ''));
            } catch (e) {
                return url;
            }
        }

        if (!url.startsWith('/') || url.startsWith('//')) return url;
        if (base === '/') return url;
        return base + url.replace(/^\//, '');
    }

    function rewriteDomAssetUrls(root) {
        if (!root || !root.querySelectorAll) return;

        var nodes = root.querySelectorAll(
            'img[src],script[src],source[src],video[src],audio[src],link[href],a[href],use[href],image[href]'
        );

        for (var i = 0; i < nodes.length; i++) {
            var el = nodes[i];
            var src = el.getAttribute('src');
            var href = el.getAttribute('href');

            if (src && src.charAt(0) === '/' && !src.startsWith('//')) {
                var fixedSrc = rewrite(src);
                if (fixedSrc !== src) el.setAttribute('src', fixedSrc);
            }

            if (href && href.charAt(0) === '/' && !href.startsWith('//')) {
                var fixedHref = rewrite(href);
                if (fixedHref !== href) el.setAttribute('href', fixedHref);
            }
        }
    }

    var _fetch = window.fetch;
    if (typeof _fetch === 'function') {
        window.fetch = function(input, init) {
            if (typeof input === 'string') return _fetch.call(this, rewrite(input), init);
            if (input && input.url && typeof Request === 'function') {
                return _fetch.call(this, new Request(rewrite(input.url), input), init);
            }
            return _fetch.call(this, input, init);
        };
    }

    if (window.XMLHttpRequest && window.XMLHttpRequest.prototype) {
        var _open = window.XMLHttpRequest.prototype.open;
        window.XMLHttpRequest.prototype.open = function(method, url) {
            arguments[1] = rewrite(url);
            return _open.apply(this, arguments);
        };
    }

    if (window.WebSocket) {
        var _WebSocket = window.WebSocket;
        window.WebSocket = function(url, protocols) {
            if (typeof url === 'string' && url.startsWith('/')) {
                var scheme = window.location.protocol === 'https:' ? 'wss://' : 'ws://';
                url = scheme + window.location.host + rewrite(url);
            }
            return new _WebSocket(url, protocols);
        };
        window.WebSocket.prototype = _WebSocket.prototype;
    }

    if (navigator.serviceWorker && navigator.serviceWorker.register) {
        var _register = navigator.serviceWorker.register.bind(navigator.serviceWorker);
        navigator.serviceWorker.register = function(scriptURL, options) {
            var fixed = rewrite(scriptURL);
            return _register(fixed, options);
        };
    }

    rewriteDomAssetUrls(document);

    if (window.MutationObserver && document && document.documentElement) {
        var mo = new MutationObserver(function(mutations) {
            for (var i = 0; i < mutations.length; i++) {
                var m = mutations[i];
                if (m.type === 'attributes' && m.target && m.target.getAttribute) {
                    rewriteDomAssetUrls(m.target.parentNode || document);
                }
                if (m.addedNodes && m.addedNodes.length) {
                    for (var j = 0; j < m.addedNodes.length; j++) {
                        var n = m.addedNodes[j];
                        if (n && n.nodeType === 1) rewriteDomAssetUrls(n);
                    }
                }
            }
        });

        mo.observe(document.documentElement, {
            subtree: true,
            childList: true,
            attributes: true,
            attributeFilter: ['src', 'href']
        });
    }
})();
</script>
EOF

        awk 'BEGIN{inserted=0} {
            print $0;
            if (!inserted && $0 ~ /<head>/) {
                while ((getline line < "/tmp/ha-ingress-compat-shim.html") > 0) print line;
                inserted=1;
            }
        }' "${INDEX_HTML}" > /tmp/index.html.patched

        mv /tmp/index.html.patched "${INDEX_HTML}"
}

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

FORCE_HTTPS=$(jq --raw-output '.force_https // false' "${OPTIONS_FILE}")
[ "${FORCE_HTTPS}" = "true" ] && export FORCE_HTTPS=true

TRUST_PROXY=$(jq --raw-output '.trust_proxy // 1' "${OPTIONS_FILE}")
[ -n "${TRUST_PROXY}" ] && export TRUST_PROXY

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
apply_ingress_compat_patch
cd /app/server
exec gosu node node --require tsconfig-paths/register dist/index.js
