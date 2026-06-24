# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A library of reusable GitHub Actions workflows for OxHive projects. Consumers call these workflows via `workflow_call` using the path `oxHive/pipelines/.github/workflows/<path>@main`.

There is no application code — everything here is YAML workflow definitions.

## Folder structure

```
.github/workflows/
├── rust/       # Rust-specific workflows
└── shared/     # Language-agnostic workflows, reusable across any language
```

**Rule:** A workflow goes in `shared/` if it has no language-specific tooling (e.g. only uses `actions/*`, `git-cliff`, `softprops/action-gh-release`). Everything that touches `cargo`, `rustfmt`, `clippy`, or crates.io goes in `rust/`.

When adding a new language, create a new top-level folder (e.g. `go/`).

## Rust release pipeline

The Rust release is a chain of reusable workflows, each independently callable:

```
rust/release.yml (orchestrator)
  ├── rust/verify-version.yml   # asserts git tag == Cargo.toml version
  ├── rust/check.yml            # fmt, clippy, test, tarpaulin coverage
  ├── rust/build-binaries.yml   # cross-compiles for linux-x86, linux-arm, darwin-arm; uploads artifacts
  ├── shared/github-release.yml # downloads artifacts, runs git-cliff, creates GH release
  └── rust/publish-crates.yml   # cargo publish --locked
```

Artifacts flow between `build-binaries` and `github-release` via the GitHub Actions artifact store (scoped to the workflow run), not through explicit outputs.

## Conventions

- **Workflow names** (`name:` field): title-case, descriptive — e.g. `Rust Build Binaries`, not `build`.
- **Job names**: snake_case matching the file name where possible — e.g. job `build-binaries` inside `build-binaries.yml`.
- **Action versions**: pin to major version tags (`@v7`, `@v2`), not floating `@latest`. Dependabot keeps these current.
- **Secrets**: declare in `workflow_call.secrets` and pass explicitly through every orchestrator layer — never rely on implicit inheritance.
- **Coverage threshold**: `rust/check.yml` defaults `fail-under-coverage` to `60`. Callers can override this input.

## Dependabot

Configured to update both `cargo` and `github-actions` dependencies weekly with the prefixes `chore(deps)` and `chore(ci)` respectively.
