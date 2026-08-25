#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

_SUPABASE_VERSION="2.20.8"
_SUPABASE_RELEASE_URL="https://github.com/supabase/cli/releases/download/v${_SUPABASE_VERSION}"
_SUPABASE_BIN="$PREFIX/bin/supabase"
_SUPABASE_MARKER="$PREFIX/share/karnel-installers/supabase"

_supabase_is_owned() {
  local recorded actual
  [[ -f "$_SUPABASE_BIN" && -f "$_SUPABASE_MARKER" ]] || return 1
  read -r recorded _ <"$_SUPABASE_MARKER" || return 1
  [[ "$recorded" =~ ^[0-9a-f]{64}$ ]] || return 1
  actual=$(sha256sum "$_SUPABASE_BIN" 2>/dev/null | awk '{print $1}') || return 1
  [[ "$recorded" == "$actual" ]]
}

install_supabase() (
  if command -v supabase &>/dev/null; then
    local current
    current=$(supabase --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    if [[ "$current" == "$_SUPABASE_VERSION" ]]; then
      log_info "supabase v$_SUPABASE_VERSION already installed"
      return 2
    fi
    log_info "Updating supabase $current → v$_SUPABASE_VERSION..."
  else
    log_info "Installing supabase v$_SUPABASE_VERSION..."
  fi

  local arch
  arch=$(uname -m)
  local go_arch
  case "$arch" in
    aarch64|arm64) go_arch="arm64" ;;
    x86_64|amd64)  go_arch="amd64" ;;
    *) log_error "Unsupported architecture: $arch"; return 1 ;;
  esac

  local filename="supabase_linux_${go_arch}.tar.gz"
  local url="${_SUPABASE_RELEASE_URL}/${filename}"
  local checksum_url="${_SUPABASE_RELEASE_URL}/supabase_${_SUPABASE_VERSION}_checksums.txt"
  local tmp_dir staged_bin marker_staging="" old_bin="" old_marker=""
  local _kdir="${KARNEL_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/karnel}"
  mkdir -p "$_kdir" 2>/dev/null || _kdir="${TMPDIR:-/tmp}"
  tmp_dir=$(mktemp -d "$_kdir/supabase.XXXXXX") || return 1
  staged_bin=""
  trap 'rm -rf "$tmp_dir"; [[ -z "$staged_bin" ]] || rm -f "$staged_bin"; [[ -z "$marker_staging" ]] || rm -f "$marker_staging"' EXIT

  if [[ -e "$_SUPABASE_BIN" ]] && ! _supabase_is_owned; then
    log_error "Refusing to replace supabase not managed by Karnel"
    return 1
  fi

  # Download binary
  if ! loading "Downloading supabase" curl -fsSL "$url" -o "$tmp_dir/$filename" ||
    [[ ! -f "$tmp_dir/$filename" ]]; then
    log_error "Failed to download supabase"
    return 1
  fi

  local expected actual binary_hash
  if ! curl -fsSL "$checksum_url" -o "$tmp_dir/checksums.txt" 2>/dev/null; then
    log_error "Failed to download Supabase checksums"
    return 1
  fi
  expected=$(awk -v file="$filename" '$2 == file || $2 == "*" file { print $1 }' "$tmp_dir/checksums.txt")
  if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
    log_error "Missing or invalid checksum for $filename"
    return 1
  fi
  actual=$(sha256sum "$tmp_dir/$filename" 2>/dev/null | awk '{print $1}') || {
    log_error "Unable to calculate Supabase checksum"
    return 1
  }
  if [[ "$expected" != "$actual" ]]; then
    log_error "Supabase checksum verification failed"
    return 1
  fi
  log_success "Checksum verified"

  # Extract
  tar -xzf "$tmp_dir/$filename" -C "$tmp_dir" supabase 2>/dev/null
  if [[ ! -f "$tmp_dir/supabase" ]]; then
    log_error "Extraction failed"
    return 1
  fi

  # Stage on the destination filesystem so activation cannot expose a partial binary.
  mkdir -p "$PREFIX/bin" "$(dirname "$_SUPABASE_MARKER")" || return 1
  staged_bin=$(mktemp "$PREFIX/bin/.supabase.XXXXXX") || return 1
  cp "$tmp_dir/supabase" "$staged_bin" && chmod +x "$staged_bin" || return 1
  binary_hash=$(sha256sum "$staged_bin" 2>/dev/null | awk '{print $1}') || return 1
  marker_staging=$(mktemp "$(dirname "$_SUPABASE_MARKER")/.supabase.XXXXXX") || return 1
  printf '%s  %s\n' "$binary_hash" "$_SUPABASE_BIN" >"$marker_staging" || return 1
  if [[ -f "$_SUPABASE_BIN" ]]; then
    old_bin="$tmp_dir/previous-supabase"
    cp -p "$_SUPABASE_BIN" "$old_bin" || return 1
  fi
  if [[ -f "$_SUPABASE_MARKER" ]]; then
    old_marker="$tmp_dir/previous-marker"
    cp -p "$_SUPABASE_MARKER" "$old_marker" || return 1
  fi
  mv -f "$staged_bin" "$_SUPABASE_BIN" || return 1
  staged_bin=""
  if ! mv -f "$marker_staging" "$_SUPABASE_MARKER"; then
    rm -f "$_SUPABASE_BIN" "$_SUPABASE_MARKER"
    [[ -z "$old_bin" ]] || mv "$old_bin" "$_SUPABASE_BIN" || return 1
    [[ -z "$old_marker" ]] || mv "$old_marker" "$_SUPABASE_MARKER" || return 1
    return 1
  fi
  marker_staging=""

  log_success "supabase v$_SUPABASE_VERSION installed ($(du -h "$_SUPABASE_BIN" | awk '{print $1}'))"

  # Doctor check
  if command -v supabase &>/dev/null; then
    local ver
    ver=$(supabase --version 2>/dev/null | head -1)
    log_info "supabase ready: $ver"
    echo
    log_info "Run 'karnel supabase doctor' for environment check"
  fi

  return 0
)

uninstall_supabase() {
  if [[ ! -f "$_SUPABASE_BIN" ]]; then
    log_info "supabase is not installed"
    return 2
  fi
  if ! _supabase_is_owned; then
    log_warn "Preserving supabase not managed by Karnel"
    return 2
  fi
  log_info "Removing supabase..."
  rm -f "$_SUPABASE_BIN" "$_SUPABASE_MARKER"
  log_info "Preserved Supabase configuration in $HOME/.supabase"
  log_success "supabase removed"
}

update_supabase() {
  install_supabase
}

reinstall_supabase() {
  uninstall_supabase
  local rc=$?
  [[ "$rc" == 0 || "$rc" == 2 ]] || return "$rc"
  install_supabase
}
