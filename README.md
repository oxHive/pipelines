# oxHive Pipelines

Reusable GitHub Actions workflows for OxHive projects. No application code lives here — everything is YAML workflow/action definitions, called from consumer repos via `workflow_call`.

## Usage

```yaml
jobs:
  release:
    uses: oxHive/pipelines/.github/workflows/rust-release.yml@v2
    with:
      package-name: mytool
      binary-name: mytool
    secrets: inherit
```

See each workflow file under [`.github/workflows/`](.github/workflows/) for its full `inputs`/`secrets` contract.

## Layout

- `rust-*.yml` — Rust-specific workflows (`rust-release.yml` is the main orchestrator; see [CLAUDE.md](CLAUDE.md) for the full pipeline breakdown)
- `shared-*.yml` — language-agnostic workflows
- `notify-matrix.yml` / `notify-discord.yml` — release/failure notifications, called from `rust-release.yml` via its `notify-provider` input
- `.github/actions/` — composite actions used as steps inside the orchestrator workflows

## Docs

- [Discord notification setup](docs/discord-setup.md) — getting a webhook URL for `notify-discord.yml`
- [Homebrew publishing via GitHub App](docs/homebrew-github-app.md) — scoped token setup for `rust-publish-homebrew`
- [Dockerfile contract for publish-docker](docs/docker-publish.md) — how to write a Dockerfile that reuses the cross-compiled binaries
