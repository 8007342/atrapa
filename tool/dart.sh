#!/usr/bin/env bash
# Run `dart <args>` in a pinned Dart SDK container when no host dart exists.
# Usage (from anywhere): tool/dart.sh -C packages/atrapa_rules test
#   -C <dir>  working directory relative to the repo root.
# Pub cache and scratch stay under the repo's gitignored target/.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
wd=.
if [ "${1:-}" = "-C" ]; then wd="$2"; shift 2; fi
if command -v dart >/dev/null 2>&1; then cd "$repo/$wd" && exec nice -n 10 dart "$@"; fi
IMAGE="docker.io/library/dart@sha256:a0796ee7c244e22ff51c26d8a622ddea811be59bb07c75650fe64bd41d760719" # dart 3.9.4
mkdir -p "$repo/target/pub-cache"
exec nice -n 10 podman run --rm --security-opt=label=disable --userns=keep-id \
  -v "$repo:/w" -w "/w/$wd" -e PUB_CACHE=/w/target/pub-cache -e HOME=/w/target \
  "$IMAGE" dart "$@"
