#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
CRUSH_VERSION="0.82.0"

install_crush() {
  if command -v crush &>/dev/null; then
    log_info "Crush is already installed"
    return 2
  fi

  log_info "Installing Crush..."

  # Try npm first
  if command -v npm &>/dev/null; then
    log_info "Attempting npm install..."
    if npm install -g @charmland/crush &>>"$LOG_FILE"; then
      if command -v crush &>/dev/null; then
        log_success "Crush installed via npm"
        return 0
      fi
    fi
    log_warn "npm install failed, trying GitHub release..."
  fi

  # Fallback: download from GitHub releases
  local arch
  arch=$(uname -m)
  local tarball="crush_${CRUSH_VERSION}_Android_arm64.tar.gz"
  local url="https://github.com/charmbracelet/crush/releases/download/v${CRUSH_VERSION}/${tarball}"

  log_info "Downloading Crush v${CRUSH_VERSION} for Android arm64..."

  local tmpdir
  tmpdir=$(mktemp -d)
  if curl -fsSL --connect-timeout 15 --max-time 120 "$url" -o "$tmpdir/$tarball" 2>>"$LOG_FILE"; then
    if tar xzf "$tmpdir/$tarball" -C "$tmpdir" 2>>"$LOG_FILE"; then
      local bin_path
      bin_path=$(find "$tmpdir" -name "crush" -type f -executable 2>/dev/null | head -1)
      if [[ -n "$bin_path" ]]; then
        rm -f "$PREFIX/bin/crush"
        cp "$bin_path" "$PREFIX/bin/crush"
        chmod +x "$PREFIX/bin/crush"
        rm -rf "$tmpdir"
        if command -v crush &>/dev/null; then
          log_success "Crush installed from GitHub release"
          return 0
        fi
      fi
    fi
  fi

  rm -rf "$tmpdir"
  log_error "Failed to install Crush"
  log_info "Check log: $LOG_FILE"
  return 1
}

uninstall_crush() {
  if ! command -v crush &>/dev/null; then
    log_info "Crush is not installed"
    return 0
  fi

  log_info "Uninstalling Crush..."
  rm -f "$PREFIX/bin/crush"
  npm uninstall -g @charmland/crush &>>"$LOG_FILE" 2>/dev/null
  log_success "Crush uninstalled"
  return 0
}

update_crush() {
  if ! command -v crush &>/dev/null; then
    log_info "Crush is not installed"
    return 0
  fi

  log_info "Updating Crush..."
  uninstall_crush
  install_crush
}

reinstall_crush() {
  uninstall_crush
  install_crush
}
