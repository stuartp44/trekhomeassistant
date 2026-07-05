# Changelog

## [3.13.5](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.13.4...trekhomeassistant-v3.13.5) (2026-07-05)


### Bug Fixes

* expose app-relative pathname to frontend for proper path handling ([0659115](https://github.com/stuartp44/trekhomeassistant/commit/0659115214e1f726a7ec9e1772a3a17c9a5aae5d))

## [3.13.4](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.13.3...trekhomeassistant-v3.13.4) (2026-07-05)


### Bug Fixes

* add self-login redirect handling in patch_static_paths function ([719c43f](https://github.com/stuartp44/trekhomeassistant/commit/719c43f7b551e2b346885a638cfb831064c3dc10))

## [3.13.3](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.13.2...trekhomeassistant-v3.13.3) (2026-07-05)


### Bug Fixes

* update URL handling in patch_static_paths and asset rewrites for HA ingress ([59f3288](https://github.com/stuartp44/trekhomeassistant/commit/59f3288bdeae511319cca020de6f2900e93e4b55))

## [3.13.2](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.13.1...trekhomeassistant-v3.13.2) (2026-07-05)


### Bug Fixes

* update script paths in index.html and nginx config for ingress runtime ([5d425f2](https://github.com/stuartp44/trekhomeassistant/commit/5d425f2f20ca783c210fa412befdcc803c794dcd))

## [3.13.1](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.13.0...trekhomeassistant-v3.13.1) (2026-07-05)


### Bug Fixes

* ensure trailing slash in extracted base path from ingress URLs ([2107f1b](https://github.com/stuartp44/trekhomeassistant/commit/2107f1b97ca5d0b19e4a55cca1f4fddfa78b426c))

## [3.13.0](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.12.0...trekhomeassistant-v3.13.0) (2026-07-05)


### Features

* apply targeted rewrites for bundled assets in run.sh ([39416d8](https://github.com/stuartp44/trekhomeassistant/commit/39416d8e49c5b44b01a5ff18652f416a1442c3ba))

## [3.12.0](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.11.0...trekhomeassistant-v3.12.0) (2026-07-05)


### Features

* enhance URL handling in patch_static_paths for improved navigation ([c1aed97](https://github.com/stuartp44/trekhomeassistant/commit/c1aed9716325721350f93abbcc94c2b30e64fde2))

## [3.11.0](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.10.0...trekhomeassistant-v3.11.0) (2026-07-05)


### Features

* enhance URL rewriting in ingress runtime shim for improved asset handling ([57bc32f](https://github.com/stuartp44/trekhomeassistant/commit/57bc32fb4a81fcab0f4674f6aa986535076f8a31))

## [3.10.0](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.9.5...trekhomeassistant-v3.10.0) (2026-07-05)


### Features

* add ingress runtime shim for URL rewriting in frontend assets ([fb0428a](https://github.com/stuartp44/trekhomeassistant/commit/fb0428a480d439b3251e92d0fb05295fa481f5a8))

## [3.9.5](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.9.4...trekhomeassistant-v3.9.5) (2026-07-05)


### Bug Fixes

* update asset paths in NGINX configuration for icons and API ([db226bf](https://github.com/stuartp44/trekhomeassistant/commit/db226bf34638ebe579c3eb372bd5c6f10a7f760e))

## [3.9.4](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.9.3...trekhomeassistant-v3.9.4) (2026-07-05)


### Bug Fixes

* update NGINX configuration to use effective ingress prefix for path handling ([fb6f897](https://github.com/stuartp44/trekhomeassistant/commit/fb6f8971d164b28a360982cb4cb945cd0c55a6a1))

## [3.9.3](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.9.2...trekhomeassistant-v3.9.3) (2026-07-05)


### Bug Fixes

* enhance static path patching in run.sh for dynamic public directory detection ([a72a661](https://github.com/stuartp44/trekhomeassistant/commit/a72a6618b22b4eb04828204264fb0ea60f9d8cfc))

## [3.9.2](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.9.1...trekhomeassistant-v3.9.2) (2026-07-05)


### Bug Fixes

* update asset paths in patch_static_paths function for improved resource loading ([8ca92a4](https://github.com/stuartp44/trekhomeassistant/commit/8ca92a4e5702874a210662dcb47a3574e0fb260f))

## [3.9.1](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.9.0...trekhomeassistant-v3.9.1) (2026-07-05)


### Bug Fixes

* update write_nginx_config to improve ingress mapping ([6362dfc](https://github.com/stuartp44/trekhomeassistant/commit/6362dfcc0c04aa3c605da363ed03f4afc7873672))

## [3.9.0](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.8.5...trekhomeassistant-v3.9.0) (2026-07-05)


### Features

* add static path patching for Home Assistant ingress compatibility ([f04b0b9](https://github.com/stuartp44/trekhomeassistant/commit/f04b0b99529953e41aa84d94db3c55f70e48a3e8))

## [3.8.4](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.8.3...trekhomeassistant-v3.8.4) (2026-07-05)

### Bug Fixes

* enhance ingress compatibility by updating form action handling and history methods ([798bc48](https://github.com/stuartp44/trekhomeassistant/commit/798bc48073fe5f3d3933da7aac13007de651364a))

## [3.8.3](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.8.2...trekhomeassistant-v3.8.3) (2026-07-05)

### Bug Fixes

* improve service worker registration handling for Home Assistant ingress ([cf16c62](https://github.com/stuartp44/trekhomeassistant/commit/cf16c62e047af2a9e5cbb4407116c76b007ccf92))

## [3.8.2](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.8.1...trekhomeassistant-v3.8.2) (2026-07-05)

### Bug Fixes

* update asset URL handling in apply_ingress_compat_patch for Home Assistant compatibility ([7c6eda4](https://github.com/stuartp44/trekhomeassistant/commit/7c6eda4b05696686aa6954b635f575d5dbc73622))

## [3.8.1](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.8.0...trekhomeassistant-v3.8.1) (2026-07-05)

### Bug Fixes

* update URL rewriting logic in ha-ingress-compat.js for improved asset loading ([f0a3b00](https://github.com/stuartp44/trekhomeassistant/commit/f0a3b00ef82875222b3f5fce099a6320514ea5e2))

## [3.8.0](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.7.0...trekhomeassistant-v3.8.0) (2026-07-05)

### Features

* add ha-ingress-compat.js for improved URL rewriting in run.sh ([f5f1bb8](https://github.com/stuartp44/trekhomeassistant/commit/f5f1bb8f0037224b5f3d40f9388c64e71051729a))

## [3.7.0](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.6.1...trekhomeassistant-v3.7.0) (2026-07-05)

### Features

* add icon and logo images; enhance URL rewriting in run.sh ([1ecfbe4](https://github.com/stuartp44/trekhomeassistant/commit/1ecfbe41aede09c1fd85b6af1315858e181aa726))

## [3.6.1](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.6.0...trekhomeassistant-v3.6.1) (2026-07-05)

### Bug Fixes

* improve version parsing in validation workflow ([6b2f9ff](https://github.com/stuartp44/trekhomeassistant/commit/6b2f9ff6b8e1cbdf05d0a3ea87b421232b2b04d3))

## [3.6.0](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.5.0...trekhomeassistant-v3.6.0) (2026-07-05)

### Features

* update validation workflow and README for add-on version consistency ([e2eaa3c](https://github.com/stuartp44/trekhomeassistant/commit/e2eaa3cb501e2a43fb161f43762101379c85dc7a))

## [3.5.0](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.4.0...trekhomeassistant-v3.5.0) (2026-07-05)

### Features

* enhance TREK add-on with Home Assistant ingress support and fallback options ([407d7c0](https://github.com/stuartp44/trekhomeassistant/commit/407d7c052ba60c54e199102f748e7b1aaea38960))

## [3.4.0](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.3.0...trekhomeassistant-v3.4.0) (2026-07-05)

### Features

* add support for HTTPS and proxy configuration in TREK add-on ([3688371](https://github.com/stuartp44/trekhomeassistant/commit/36883718038433238621a23977faf9cfdaa87468))

## [3.3.0](https://github.com/stuartp44/trekhomeassistant/compare/trekhomeassistant-v3.2.0...trekhomeassistant-v3.3.0) (2026-07-05)

### Features

* add parser preset configuration to commitlint ([26b8b1e](https://github.com/stuartp44/trekhomeassistant/commit/26b8b1e110dbd6c224de043d5d5c331582bb6dba))
