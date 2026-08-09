#!/usr/bin/env bash
set -Eeuo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"

export BUILDER_UID=${BUILDER_UID:-$(id -u)}
export BUILDER_GID=${BUILDER_GID:-$(id -g)}

action=${1:-build}

case "$action" in
  image)
    docker compose build lede-builder
    ;;
  check)
    docker compose build lede-builder
    docker compose run --rm --entrypoint /bin/bash lede-builder -lc \
      'printf "architecture=%s user=%s uid=%s cpus=%s memory_kib=%s\n" "$(uname -m)" "$(id -un)" "$(id -u)" "$(nproc)" "$(awk '\''/MemTotal/ {print $2}'\'' /proc/meminfo)"; command -v gcc git go make python3 rsync; go version; go env GOROOT'
    ;;
  shell)
    docker compose build lede-builder
    docker compose run --rm --entrypoint /bin/bash lede-builder
    ;;
  build)
    docker compose build lede-builder
    docker compose run --rm lede-builder
    ;;
  *)
    echo "Usage: $0 [image|check|shell|build]" >&2
    exit 2
    ;;
esac
