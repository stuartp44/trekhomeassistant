# TREK Home Assistant Add-ons

[![License: MIT](https://img.shields.io/badge/license-MIT-6B7280?style=flat-square)](LICENSE)

A Home Assistant add-on repository that packages [TREK](https://github.com/mauriceboe/TREK), a self-hosted real-time collaborative travel planner, so it runs natively inside your Home Assistant instance.

## Upstream Credit

- Upstream project: [mauriceboe/TREK](https://github.com/mauriceboe/TREK)
- Creator and maintainer: [Maurice Boehm (@mauriceboe)](https://github.com/mauriceboe)
- This repository provides Home Assistant add-on packaging for the upstream TREK Docker image.
- This repository is unofficial and is not affiliated with the upstream TREK maintainers.

## Add-ons

### [TREK](trek/)

A self-hosted travel planner with interactive maps, trip budgets, packing lists,
a travel journal, and a built-in MCP server for AI assistants.

## Installation

1. Open Home Assistant and go to **Settings → Add-ons → Add-on Store**.
2. Click the three-dot menu (⋮) in the top-right corner and choose
   **Repositories**.
3. Add the following URL:
   ```
   https://github.com/stuartp44/trekhomeassistant
   ```
4. Find the **TREK** add-on in the store and click **Install**.

The add-on is configured for direct Web UI access on port `3000`:

- `http://<ha-host>:3000`

## Support

- TREK application issues → [mauriceboe/TREK](https://github.com/mauriceboe/TREK/issues)
- Add-on packaging issues → [stuartp44/trekhomeassistant](https://github.com/stuartp44/trekhomeassistant/issues)

## Releases

This repository uses `release-please`.

- Merge conventional commits into `main` (for example: `feat:`, `fix:`, `chore:`).
- GitHub Actions opens/updates a release PR with changelog updates.
- Merging that release PR creates the GitHub release and tag.
- Release PRs also update the add-on version in `trek/config.yaml`.
- Human-readable release notes are published in [trek/CHANGELOG.md](trek/CHANGELOG.md).
- GitHub release pages are available at [Releases](https://github.com/stuartp44/trekhomeassistant/releases).

Non-conventional historic commits are bootstrapped from the release pipeline.
From now on, keep commit messages conventional so releases are generated correctly.
Examples: `chore: adjust release pipeline`, `fix: correct add-on validation`, `feat: add new add-on option`.
Also accepted by CI: `[feat] add new add-on option`, `[fix] correct add-on validation`.
GitHub Actions enforces this via the `commitlint` workflow on pull requests and pushes to `main`.

The TREK add-on version is pinned to an explicit upstream TREK release (never
`latest`) and is managed by Renovate.

## Version Pinning And Auto-Bump

- `trek/build.yaml` pins both architectures to `mauriceboe/trek:<version>`.
- `trek/config.yaml` stores the add-on release version.
- `test-addon-version` workflow tests that pinned versions are consistent.
- Renovate watches upstream `mauriceboe/trek` tags and opens PRs when updates
  are available.

## License

- Add-on wrapper repository license: [MIT](LICENSE)
- Upstream TREK license: [AGPL-3.0](https://github.com/mauriceboe/TREK/blob/main/LICENSE)

Use of the upstream TREK image and software remains subject to upstream license terms.
