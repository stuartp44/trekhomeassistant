# TREK Home Assistant Add-ons

[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-6B7280?style=flat-square)](https://github.com/mauriceboe/TREK/blob/main/LICENSE)

A Home Assistant add-on repository that packages [TREK](https://github.com/mauriceboe/TREK), a self-hosted real-time collaborative travel planner, so it runs natively inside your Home Assistant instance.

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

## Support

- TREK application issues → [mauriceboe/TREK](https://github.com/mauriceboe/TREK/issues)
- Add-on packaging issues → [stuartp44/trekhomeassistant](https://github.com/stuartp44/trekhomeassistant/issues)

## Releases

This repository uses `release-please`.

- Merge conventional commits into `main` (for example: `feat:`, `fix:`, `chore:`).
- GitHub Actions opens/updates a release PR with changelog updates.
- Merging that release PR creates the GitHub release and tag.

Non-conventional historic commits are bootstrapped from the release pipeline.
From now on, keep commit messages conventional so releases are generated correctly.

The TREK add-on version is pinned to an explicit upstream TREK release (never
`latest`) and is managed by Renovate.

## Version Pinning And Auto-Bump

- `trek/build.yaml` pins both architectures to `mauriceboe/trek:<version>`.
- `trek/config.yaml` uses the same pinned version.
- `test-addon-version` workflow tests that pinned versions are consistent.
- Renovate watches upstream `mauriceboe/trek` tags and opens PRs when updates
   are available.

## License

This add-on wrapper is provided under the same [AGPL-3.0](https://github.com/mauriceboe/TREK/blob/main/LICENSE)
license as the upstream TREK project.
