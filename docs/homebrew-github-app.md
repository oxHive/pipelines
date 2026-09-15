# HOMEBREW_TAP_TOKEN via GitHub App

`rust-publish-homebrew` needs a token with `contents: write` on the Homebrew tap repo (default `oxhive/homebrew-tap`), passed to `Justintime50/homebrew-releaser` as `github_token`. A long-lived PAT (`HOMEBREW_TAP_TOKEN` secret) works, but a GitHub App installation token is preferred — scoped to one repo, rotates per run, not tied to a person's account. The `rust-publish-homebrew` action mints the token itself when App credentials are supplied, so consumers don't need any extra jobs.

## Setup

1. Create a GitHub App with `Contents: Read & write` permission. Install it only on the tap repo (e.g. `oxhive/homebrew-tap`), not org-wide.
2. Generate a private key for the App.
3. Store the App ID and private key as secrets on the consumer repo (or org): `HOMEBREW_APP_ID`, `HOMEBREW_APP_PRIVATE_KEY`.
4. Pass them through to `rust-release.yml` like any other secret:

```yaml
jobs:
  release:
    uses: oxHive/pipelines/.github/workflows/rust-release.yml@v2
    with:
      publish-homebrew: true
      # ...
    secrets: inherit
    # or, if not using inherit:
    # secrets:
    #   HOMEBREW_APP_ID: ${{ secrets.HOMEBREW_APP_ID }}
    #   HOMEBREW_APP_PRIVATE_KEY: ${{ secrets.HOMEBREW_APP_PRIVATE_KEY }}
```

`rust-release.yml` forwards `HOMEBREW_APP_ID`/`HOMEBREW_APP_PRIVATE_KEY` into `rust-publish-homebrew`, which mints an installation token via `actions/create-github-app-token` before calling `Justintime50/homebrew-releaser`. If `HOMEBREW_APP_ID` is unset, it falls back to `HOMEBREW_TAP_TOKEN` (a plain PAT) instead — set one or the other, not both.
