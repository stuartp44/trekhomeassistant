# Copilot Instructions

This repository packages the TREK Home Assistant add-on. Follow these rules for all changes.

## Commit Message Rules

- Use Conventional Commits for all commits.
- Allowed types: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`.
- Format: `<type>: <short description>`.
- Examples:
  - `chore: adjust release pipeline`
  - `fix: correct add-on validation`
  - `feat: add new add-on option`

## TREK Version Pinning

- Never use `latest` for TREK image tags.
- Keep versions aligned between:
  - `trek/config.yaml` -> `version`
  - `trek/build.yaml` -> `build_from.amd64` and `build_from.aarch64`
- If one is changed, update all three values in the same PR.

## Release Automation

- `release-please` is used for changelog/release PRs and tags.
- Keep release workflow on `googleapis/release-please-action@v5`.
- Do not remove `bootstrap-sha` from `release-please-config.json` unless intentionally re-baselining history.

## Dependency Bumps

- Renovate handles upstream TREK version bump PRs.
- Do not reintroduce custom manual bump workflows for upstream version tracking unless explicitly requested.

## CI Expectations

- Keep workflows passing:
  - commitlint
  - test-addon-version
  - release-please
- If a change affects workflow behavior, update README release/versioning documentation in the same PR.

## Scope Discipline

- Keep changes minimal and targeted.
- Do not rename addon slug (`trek`) unless explicitly requested.
- Preserve Home Assistant add-on compatibility settings unless there is a specific requirement to change them.
