# Dockerfile contract for publish-docker

`publish-docker` doesn't build your binary — it reuses the binaries `rust-build-binaries` already cross-compiled. It downloads the `x86_64-unknown-linux-gnu` and `aarch64-unknown-linux-gnu` artifacts and extracts them to:

```
<docker-context>/dist/linux-amd64/<binary-name>
<docker-context>/dist/linux-arm64/<binary-name>
```

Your Dockerfile just needs to `COPY` the right one for the platform being built, using the [automatic `TARGETARCH` build arg](https://docs.docker.com/build/building/multi-platform/#automatic-target-platform-arguments-in-global-scope) buildx sets per platform:

```dockerfile
FROM debian:bookworm-slim
ARG TARGETARCH
COPY dist/linux-${TARGETARCH}/mytool /usr/local/bin/mytool
ENTRYPOINT ["/usr/local/bin/mytool"]
```

No `RUN cargo build` and no QEMU setup — since the Dockerfile only copies a pre-built binary (no target-architecture code executes during the build), buildx builds both `linux/amd64` and `linux/arm64` natively in one pass.

## Usage

```yaml
jobs:
  release:
    uses: oxHive/pipelines/.github/workflows/rust-release.yml@v2
    with:
      package-name: mytool
      binary-name: mytool
      publish-docker: true
      # docker-image-name defaults to package-name; docker-context/dockerfile default to "." / "Dockerfile"
    secrets: inherit
```

Images are pushed to `ghcr.io/<owner>/<docker-image-name or package-name>`, tagged with the release version and `latest`. Requires `packages: write` on the `GITHUB_TOKEN`, which `rust-release.yml` already grants to the `publish-docker` job.
