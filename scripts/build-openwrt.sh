#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR=/work/openwrt
CONFIG_FILE=/input/.config
DOWNLOAD_DIR=/downloads
OUTPUT_ROOT=/output

LEDE_REPOSITORY=${LEDE_REPOSITORY:-https://github.com/coolsnowwolf/lede.git}
LEDE_BRANCH=${LEDE_BRANCH:-master}
LEDE_REF=${LEDE_REF:-}
DOWNLOAD_JOBS=${DOWNLOAD_JOBS:-8}
BUILD_JOBS=${BUILD_JOBS:-8}

log() {
  printf '\n[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

if [ "$(uname -m)" != "aarch64" ]; then
  echo "This build container must run as linux/arm64." >&2
  exit 1
fi

if [ "$(id -u)" = "0" ]; then
  echo "LEDE must not be compiled as root." >&2
  exit 1
fi

if [ ! -r "$CONFIG_FILE" ]; then
  echo "Missing readable build configuration: $CONFIG_FILE" >&2
  exit 1
fi

log "Preparing LEDE source"
if [ ! -d "$SOURCE_DIR/.git" ]; then
  git clone --depth 1 --branch "$LEDE_BRANCH" "$LEDE_REPOSITORY" "$SOURCE_DIR"
else
  git -C "$SOURCE_DIR" remote set-url origin "$LEDE_REPOSITORY"
fi

if [ -n "$LEDE_REF" ]; then
  git -C "$SOURCE_DIR" fetch --depth 1 origin "$LEDE_REF"
  git -C "$SOURCE_DIR" checkout --detach FETCH_HEAD
else
  git -C "$SOURCE_DIR" fetch --depth 1 origin "$LEDE_BRANCH"
  git -C "$SOURCE_DIR" checkout "$LEDE_BRANCH"
  git -C "$SOURCE_DIR" merge --ff-only FETCH_HEAD
fi

cd "$SOURCE_DIR"
cp feeds.conf.default feeds.conf
sed -i 's/^#src-git helloworld/src-git helloworld/' feeds.conf

log "Updating and installing feeds"
./scripts/feeds update -a
./scripts/feeds install -a

log "Applying files/.config"
cp "$CONFIG_FILE" .config

# The legacy Go 1.4 C bootstrap bundled by the feed cannot run on
# linux/arm64. Use the Go installation contained in this image, matching the
# upstream darwin/arm64 path without installing anything on macOS.
go_bootstrap_root="$(go env GOROOT)"
if [ -z "$go_bootstrap_root" ] || [ ! -x "$go_bootstrap_root/bin/go" ]; then
  echo "A working Go bootstrap toolchain was not found in the container." >&2
  exit 1
fi
if grep -q '^CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT=' .config; then
  sed -i "s|^CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT=.*|CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT=\"${go_bootstrap_root}\"|" .config
else
  printf 'CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT="%s"\n' "$go_bootstrap_root" >> .config
fi
log "Using container Go bootstrap: $go_bootstrap_root ($(go version))"

make defconfig
if grep -q '^CONFIG_PACKAGE_luci-theme-argon=y$' .config; then
  log "luci-theme-argon is enabled"
fi

log "Downloading source archives with ${DOWNLOAD_JOBS} jobs"
make DL_DIR="$DOWNLOAD_DIR" download -j"$DOWNLOAD_JOBS"

log "Compiling firmware with ${BUILD_JOBS} jobs"
if ! make DL_DIR="$DOWNLOAD_DIR" -j"$BUILD_JOBS"; then
  log "Parallel build failed; retrying serially with verbose output"
  make DL_DIR="$DOWNLOAD_DIR" -j1 V=s
fi

revision="$(git rev-parse --short=12 HEAD)"
build_stamp="$(date '+%Y%m%d-%H%M%S')-${revision}"
destination="$OUTPUT_ROOT/$build_stamp"

log "Exporting artifacts to $destination"
mkdir -p "$destination/firmware" "$destination/packages" "$destination/buildinfo"
cp .config "$destination/buildinfo/.config"
cp feeds.conf "$destination/buildinfo/feeds.conf"
printf '%s\n' "$(git rev-parse HEAD)" > "$destination/buildinfo/lede-revision.txt"

if [ -d bin/targets ]; then
  cp -a bin/targets/. "$destination/firmware/"
fi
if [ -d bin/packages ]; then
  cp -a bin/packages/. "$destination/packages/"
fi

log "Build completed: $destination"
