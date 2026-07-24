#!/usr/bin/env bash

_SUPABASE_VERSION="2.20.8"
_SUPABASE_RELEASE_URL="https://github.com/supabase/cli/releases/download/v${_SUPABASE_VERSION}"
_SUPABASE_BIN="$PREFIX/bin/supabase"

install_supabase() {
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
  local tmp_dir
  tmp_dir=$(mktemp -d)

  # Download binary
  loading "Downloading supabase" curl -fsSL "$url" -o "$tmp_dir/$filename"
  if [[ $? -ne 0 || ! -f "$tmp_dir/$filename" ]]; then
    rm -rf "$tmp_dir"
    log_error "Failed to download supabase"
    return 1
  fi

  # Download checksums (optional — warn if unavailable rather than fail)
  local checksum_ok=false
  if curl -fsSL "$checksum_url" -o "$tmp_dir/checksums.txt" 2>/dev/null; then
    local expected
    expected=$(grep "$filename" "$tmp_dir/checksums.txt" | awk '{print $1}')
    if [[ -n "$expected" ]]; then
      local actual
      actual=$(sha256sum "$tmp_dir/$filename" | awk '{print $1}')
      if [[ "$expected" == "$actual" ]]; then
        checksum_ok=true
        log_success "Checksum verified"
      else
        log_warn "Checksum mismatch! Expected $expected, got $actual"
        read_confirm "Continue with unverified binary?" confirm
        [[ "$confirm" != "y" ]] && { rm -rf "$tmp_dir"; log_info "Cancelled"; return 1; }
      fi
    fi
  fi
  if ! $checksum_ok; then
    log_warn "Checksum verification skipped (no checksums available)"
  fi

  # Extract
  tar -xzf "$tmp_dir/$filename" -C "$tmp_dir" supabase 2>/dev/null
  if [[ ! -f "$tmp_dir/supabase" ]]; then
    rm -rf "$tmp_dir"
    log_error "Extraction failed"
    return 1
  fi

  # Install
  cp "$tmp_dir/supabase" "$_SUPABASE_BIN"
  chmod +x "$_SUPABASE_BIN"
  rm -rf "$tmp_dir"

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
}

uninstall_supabase() {
  if [[ ! -f "$_SUPABASE_BIN" ]]; then
    log_info "supabase is not installed"
    return 2
  fi
  log_info "Removing supabase..."
  rm -f "$_SUPABASE_BIN" "$HOME/.supabase"
  log_success "supabase removed"
}

update_supabase() {
  install_supabase
}

reinstall_supabase() {
  uninstall_supabase
  install_supabase
}
