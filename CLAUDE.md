# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A library of reusable GitHub Actions workflows for OxHive projects. Consumers call these workflows via `workflow_call` using the path `oxHive/pipelines/.github/workflows/<filename>@main`.

There is no application code — everything here is YAML workflow definitions.

## File naming

GitHub Actions requires reusable workflows to live at the **top level** of `.github/workflows/` — subdirectories are not supported for `workflow_call`. Files are prefixed by language or scope instead:

- `rust-*.yml` — Rust-specific workflows
- `shared-*.yml` — Language-agnostic, reusable across any language

When adding a new language, follow the same prefix convention (e.g. `go-check.yml`, `go-release.yml`).

## Rust release pipeline

`rust-release.yml` is the only reusable *workflow* consumers call. Every step it runs is a composite action in `.github/actions/<name>/`:

```
rust-release.yml (orchestrator, workflow_call)
  ├── rust-verify-version   # asserts git tag == Cargo.toml version
  ├── rust-check            # fmt, clippy, tarpaulin coverage
  ├── rust-audit            # cargo audit
  ├── bun-build             # builds an optional embedded dashboard
  ├── rust-build-binaries   # cross-compiles per target (the matrix lives in rust-release.yml)
  ├── github-release        # downloads artifacts, runs git-cliff, creates GH release
  ├── rust-publish-crates   # cargo publish --locked
  └── rust-publish-homebrew # repackages artifacts, pushes a formula to the tap
```

`shared-notify-matrix.yml` stays a reusable workflow (job-level `if:` plus per-call secrets). Composite actions can't declare `permissions:`, so the `checks: write` / `id-token: write` / `contents: write` grants live on the corresponding jobs in `rust-release.yml`.

Artifacts flow between `rust-build-binaries` and `github-release` via the GitHub Actions artifact store (scoped to the workflow run), not through explicit outputs.

## Conventions

- **Workflow names** (`name:` field): title-case, descriptive — e.g. `Rust Build Binaries`, not `build`.
- **Job names**: kebab-case matching the file name where possible — e.g. job `build-binaries` inside `rust-build-binaries.yml`.
- **Action versions**: pin to major version tags (`@v7`, `@v2`), not floating `@latest`. Dependabot keeps these current.
- **Internal `uses:` refs**: every `oxHive/pipelines/.github/...` reference inside this repo is pinned to the current major tag (`@v3`). A consumer's `rust-release.yml@v3` pin does NOT propagate to the nested `uses:` inside it, so each must carry the ref itself and they must all match. `scripts/pin-refs.sh v4` rewrites them on a major bump; `scripts/pin-refs.sh --check` (run by `lint.yml`) fails CI on drift.
- **Secrets**: declare in `workflow_call.secrets` and pass explicitly through every orchestrator layer — never rely on implicit inheritance.
- **Coverage threshold**: `rust-check.yml` defaults `fail-under-coverage` to `60`. Callers can override this input.

## Dependabot

Configured to update both `cargo` and `github-actions` dependencies weekly with the prefixes `chore(deps)` and `chore(ci)` respectively.
