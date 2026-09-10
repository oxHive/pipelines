#!/usr/bin/env bash
# Pin (or verify) this repo's internal `uses:` refs to a single git ref.
#
# Consumers pin `rust-release.yml@vN`, but GitHub does NOT propagate that ref to
# the nested `uses:` inside it -- each one resolves at its own literal ref. So
# every self-reference (oxHive/pipelines/.github/...) must carry the ref itself,
# and they must all match, or a `@vN` consumer gets a mismatched pipeline.
#
#   scripts/pin-refs.sh v3           rewrite every internal ref to @v3
#   scripts/pin-refs.sh --check      exit 1 unless every internal ref matches (CI)
#   scripts/pin-refs.sh --check v3   also assert that shared ref is exactly @v3
set -euo pipefail

slug="oxHive/pipelines"
check=0
[[ "${1:-}" == "--check" ]] && { check=1; shift; }
ref="${1:-}"

cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

refs=$(grep -rhoE "${slug}/\.github/[^@[:space:]]+@[^[:space:]\"']+" .github/ \
       | sed -E 's/.*@//' | sort -u)

if [[ $check -eq 1 ]]; then
  if [[ $(wc -l <<<"$refs") -ne 1 ]]; then
    echo "internal refs disagree:" >&2
    grep -rnoE "${slug}/\.github/\S+@\S+" .github/ >&2
    exit 1
  fi
  if [[ -n "$ref" && "$refs" != "$ref" ]]; then
    echo "internal refs are @${refs}, expected @${ref}" >&2
    exit 1
  fi
  echo "ok: all internal refs pinned to @${refs}"
  exit 0
fi

[[ -n "$ref" ]] || { echo "usage: pin-refs.sh [--check] <ref>" >&2; exit 1; }
mapfile -t files < <(grep -rlE "${slug}/\.github/" .github/)
for f in "${files[@]}"; do
  sed -i -E "s|(${slug}/\.github/[^@[:space:]]+)@[^[:space:]\"']+|\1@${ref}|g" "$f"
done
echo "pinned ${#files[@]} file(s) to @${ref}:"
grep -rnE "${slug}/\.github/" .github/
