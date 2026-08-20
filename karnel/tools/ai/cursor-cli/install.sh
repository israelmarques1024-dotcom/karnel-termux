#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/version"

: "${KARNEL_CACHE:=${XDG_CACHE_HOME:-$HOME/.cache}/karnel}"
: "${KARNEL_DATA:=${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data}"
LOG_FILE="$KARNEL_CACHE/install_ai.log"
CURSOR_DATA_DIR="$KARNEL_DATA/cursor"
_CURSOR_MARKER="$PREFIX/share/karnel-installers/cursor-cli"
_CURSOR_DATA_MARKER="$CURSOR_DATA_DIR/.karnel-managed"
_CURSOR_DATA_MANIFEST="$CURSOR_DATA_DIR/.karnel-manifest"
_CURSOR_DATA_INVENTORY="$CURSOR_DATA_DIR/.karnel-inventory"

_cursor_data_inventory() {
  find "$CURSOR_DATA_DIR" -mindepth 1 \
    ! -name '.karnel-managed' ! -name '.karnel-manifest' ! -name '.karnel-inventory' \
    -printf '%y %P\n' | LC_ALL=C sort
}

_cursor_write_data_metadata() {
  mkdir -p "$CURSOR_DATA_DIR" "$(dirname "$_CURSOR_MARKER")" || return 1
  printf '%s\n' 'Karnel Cursor CLI data' >"$_CURSOR_DATA_MARKER" || return 1
  _cursor_data_inventory >"$_CURSOR_DATA_INVENTORY" || return 1
  find "$CURSOR_DATA_DIR" -type f \
    ! -name '.karnel-managed' ! -name '.karnel-manifest' ! -name '.karnel-inventory' \
    -exec sha256sum {} + | LC_ALL=C sort >"$_CURSOR_DATA_MANIFEST"
}

_cursor_data_is_karnel_owned() {
  [ -f "$_CURSOR_DATA_MARKER" ] && [ -f "$_CURSOR_DATA_MANIFEST" ] && [ -f "$_CURSOR_DATA_INVENTORY" ] &&
    [ "$(<"$_CURSOR_DATA_MARKER")" = 'Karnel Cursor CLI data' ] &&
    cmp -s "$_CURSOR_DATA_INVENTORY" <(_cursor_data_inventory) &&
    (cd / && sha256sum -c "$_CURSOR_DATA_MANIFEST" >/dev/null 2>&1)
}

_cursor_wrapper_is_karnel_owned() {
  [ -f "$_CURSOR_MARKER" ] &&
    [ "$(sha256sum "$PREFIX/bin/cursor" 2>/dev/null)" = "$(<"$_CURSOR_MARKER")" ] &&
    grep -qF '# Karnel-managed Cursor CLI wrapper' "$PREFIX/bin/cursor"
}

_cursor_alias_is_karnel_owned() {
  [ -L "$PREFIX/bin/cursor-agent" ] &&
    [ "$(readlink "$PREFIX/bin/cursor-agent")" = "$PREFIX/bin/cursor" ]
}

_cursor_detect_ubuntu_root() {
  local root
  root="$(find /data/data/com.termux -maxdepth 10 -type d \
    -name "rootfs" -path "*/containers/ubuntu/*" 2>/dev/null | head -1)"
  if [ -z "$root" ]; then
    root="$(find /data/data/com.termux -maxdepth 10 -type d \
      -name "ubuntu" -path "*/installed-rootfs/*" 2>/dev/null | head -1)"
  fi
  echo "$root"
}

_cursor_proot_ubuntu() {
  proot-distro login --shared-tmp ubuntu -- "$@"
}

_get_latest_cursor_version_raw() {
  curl -fsS "https://cursor.com/install" 2>/dev/null | grep -oP 'downloads\.cursor\.com/lab/\K[^/]+'
}

_get_latest_cursor_version() {
  local raw
  raw=$(_spin_capture "Checking cursor.com" _get_latest_cursor_version_raw)
  [ -n "$raw" ] && echo "$raw" || echo ""
}

_get_latest_cursor_version_silent() {
  _get_latest_cursor_version_raw
}

_cursor_install_deps_native() {
  loading "Installing glibc and dependencies" _cursor_install_deps_native_impl
}

_cursor_install_deps_native_impl() {
  if [[ ! -f $PREFIX/etc/apt/sources.list.d/glibc.list ]]; then
    if ! pkg install glibc-repo -y &>>"$LOG_FILE"; then
      log_error "Failed to install glibc-repo"
      return 1
    fi
  fi
  if [[ ! -f $PREFIX/glibc/lib/libc.so.6 ]]; then
    if ! pkg install glibc -y &>>"$LOG_FILE"; then
      log_error "Failed to install glibc"
      return 1
    fi
  fi
  for pkg in curl tar; do
    if ! command -v "$pkg" &>/dev/null; then
      if ! pkg install "$pkg" -y &>>"$LOG_FILE"; then
        log_error "Failed to install $pkg"
        return 1
      fi
    fi
  done
  return 0
}

_download_cursor_binary() {
  loading "Downloading Cursor CLI" _download_cursor_binary_impl
}

_download_cursor_binary_impl() {
  case "$(uname -m)" in
    aarch64|arm64) ;;
    *) log_error "Cursor CLI Linux ARM64 asset is unavailable for architecture: $(uname -m)"; return 1 ;;
  esac

  local latest_version
  latest_version=$(_get_latest_cursor_version_silent)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Cursor CLI version"
    return 1
  fi

  mkdir -p "$(dirname "$CURSOR_DATA_DIR")"
  local staging_dir
  staging_dir="$(mktemp -d "$(dirname "$CURSOR_DATA_DIR")/.cursor.XXXXXX")" || return 1

  local tarball="agent-cli-package.tar.gz"
  local download_url="https://downloads.cursor.com/lab/$latest_version/linux/arm64/$tarball"

  # Cursor does not publish a verifiable checksum for this asset, so integrity
  # relies on HTTPS transport only; upstream does not publish a verifiable checksum.
  if ! curl -fsSL "$download_url" -o "$staging_dir/$tarball" &>>"$LOG_FILE"; then
    rm -rf "$staging_dir"
    log_error "Failed to download Cursor CLI binary"
    return 1
  fi

  if ! tar -zxf "$staging_dir/$tarball" --strip-components=1 -C "$staging_dir" &>>"$LOG_FILE"; then
    rm -rf "$staging_dir"
    log_error "Failed to extract Cursor CLI binary"
    return 1
  fi
  rm -f "$staging_dir/$tarball"

  if [ ! -f "$staging_dir/cursor-agent" ] || [ ! -f "$staging_dir/index.js" ]; then
    rm -rf "$staging_dir"
    log_error "Cursor CLI bundle incomplete after extraction (missing cursor-agent or index.js)"
    return 1
  fi

  chmod +x "$staging_dir/cursor-agent" "$staging_dir/node" 2>/dev/null || true

  local old_dir="${CURSOR_DATA_DIR}.previous.$$"
  if [[ -e "$CURSOR_DATA_DIR" ]] && ! mv "$CURSOR_DATA_DIR" "$old_dir"; then
    rm -rf "$staging_dir"
    return 1
  fi
  if ! mv "$staging_dir" "$CURSOR_DATA_DIR"; then
    [[ -e "$old_dir" ]] && mv "$old_dir" "$CURSOR_DATA_DIR"
    rm -rf "$staging_dir"
    return 1
  fi
  rm -rf "$old_dir"
  _cursor_write_data_metadata || return 1
  return 0
}

_create_cursor_wrapper() {
  mkdir -p "$PREFIX/bin" "$(dirname "$_CURSOR_MARKER")" || return 1
  if [ ! -f "$CURSOR_DATA_DIR/node" ]; then
    log_error "Bundled node not found at $CURSOR_DATA_DIR/node"
    return 1
  fi
  if [[ -e "$PREFIX/bin/cursor" ]] && ! _cursor_wrapper_is_karnel_owned; then
    log_error "Refusing to replace unowned command: $PREFIX/bin/cursor"
    return 1
  fi
  if [[ -e "$PREFIX/bin/cursor-agent" || -L "$PREFIX/bin/cursor-agent" ]] && ! _cursor_alias_is_karnel_owned; then
    log_error "Refusing to replace unowned command: $PREFIX/bin/cursor-agent"
    return 1
  fi

  local temporary
  temporary="$(mktemp "$PREFIX/bin/.cursor.XXXXXX")" || return 1
  cat >"$temporary" <<WRAPPER
#!$PREFIX/bin/env bash
# Karnel-managed Cursor CLI wrapper
set -euo pipefail
unset LD_PRELOAD LD_LIBRARY_PATH

export GODEBUG=netdns=cgo
export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"
export CURSOR_INVOKED_AS="\${0##*/}"

CURSOR_DATA_DIR="$CURSOR_DATA_DIR"

# compile cache = startup mais rapido (Node >= 22.1.0)
export NODE_COMPILE_CACHE="\${XDG_CACHE_HOME:-\$HOME/.cache}/cursor-compile-cache"

# OAuth callback precisa de HOST local
export HOST="\${HOST:-127.0.0.1}"

# BROWSER: termux-open-url ou fallback
if [ -z "\${BROWSER:-}" ] && command -v termux-open-url &>/dev/null; then
  BROWSER="termux-open-url"
fi
export BROWSER

# rodar node do bundle via ld-linux glibc
exec "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" \
  --library-path "$PREFIX/glibc/lib" \
  "\$CURSOR_DATA_DIR/node" \
  "\$CURSOR_DATA_DIR/index.js" \
  "\$@"
WRAPPER
  chmod +x "$temporary" || { rm -f "$temporary"; return 1; }
  mv -f "$temporary" "$PREFIX/bin/cursor" || return 1
  sha256sum "$PREFIX/bin/cursor" >"$_CURSOR_MARKER" || return 1
  if [ -L "$PREFIX/bin/cursor-agent" ] && ! _cursor_alias_is_karnel_owned; then
    rm -f "$PREFIX/bin/cursor-agent"
  fi
  ln -sf "$PREFIX/bin/cursor" "$PREFIX/bin/cursor-agent"
  return 0
}

install_cursor_cli() {
  if _cursor_wrapper_is_karnel_owned && _cursor_data_is_karnel_owned; then
    log_info "Cursor CLI is already installed"
    return 2
  fi
  if [ -e "$CURSOR_DATA_DIR" ] && ! _cursor_data_is_karnel_owned; then
    log_warn "Keeping existing Cursor CLI data not managed by Karnel"
    return 1
  fi

  _cursor_install_deps_native || return 1
  _download_cursor_binary || return 1
  _create_cursor_wrapper || return 1

  log_success "Cursor CLI installed"
  log_info "Run: cursor"
  return 0
}

uninstall_cursor_cli() {
  if ! _cursor_wrapper_is_karnel_owned && ! _cursor_data_is_karnel_owned; then
    if [ -e "$PREFIX/bin/cursor" ] || [ -e "$PREFIX/bin/cursor-agent" ] || [ -e "$CURSOR_DATA_DIR" ]; then
      log_error "Refusing to remove a Cursor CLI installation not owned by Karnel"
      return 1
    fi
    log_info "Cursor CLI is not installed"
    return 2
  fi
  if _cursor_wrapper_is_karnel_owned; then
    rm -f "$PREFIX/bin/cursor"
    _cursor_alias_is_karnel_owned && rm -f "$PREFIX/bin/cursor-agent"
    rm -f "$_CURSOR_MARKER"
  fi
  _cursor_data_is_karnel_owned && rm -rf "$CURSOR_DATA_DIR"
  log_success "Cursor CLI uninstalled"
  return 0
}

update_cursor_cli() {
  _check_update_needed "Cursor CLI" \
    "$(_get_installed_version cursor-agent 2>/dev/null || echo 0)" \
    "$(_parse_version "$(_get_latest_cursor_version_silent)")" \
    _update_cursor_cli_impl
}

_update_cursor_cli_impl() {
  _cursor_install_deps_native || return 1
  _download_cursor_binary || return 1
  _create_cursor_wrapper || return 1
}

reinstall_cursor_cli() {
  if command -v cursor &>/dev/null; then
    _update_cursor_cli_impl
  else
    install_cursor_cli
  fi
}