#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_deploy.log"
RAILWAY_DATA_DIR="$HOME/.local/share/karnel-data/railway"

_install_railway_manual() {
  loading "Downloading Railway CLI for ARM64" _install_railway_manual_impl
}

_install_railway_manual_impl() {
  mkdir -p "$RAILWAY_DATA_DIR"

  local latest_version
  latest_version=$(curl -fsSL --connect-timeout 10 "https://api.github.com/repos/railwayapp/cli/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  
  if [ -z "$latest_version" ]; then
    log_warn "Cannot fetch latest Railway version from GitHub API"
    return 1
  fi

  local version="${latest_version#v}"

  local tarball_url="https://github.com/railwayapp/cli/releases/download/${latest_version}/railway-${version}-aarch64-linux.tar.gz"
  local binary_name="railway"

  log_info "Downloading Railway ${version} for ARM64 Linux..."
  if ! curl -fsSL --connect-timeout 15 "$tarball_url" -o "$RAILWAY_DATA_DIR/railway.tar.gz" 2>>"$LOG_FILE"; then
    log_warn "ARM64 binary not available. Railway CLI does not provide ARM Linux builds."
    log_info "Use 'npx @railway/cli' instead."
    return 1
  fi

  tar -zxf "$RAILWAY_DATA_DIR/railway.tar.gz" -C "$RAILWAY_DATA_DIR" 2>>"$LOG_FILE" || {
    rm -f "$RAILWAY_DATA_DIR/railway.tar.gz"
    return 1
  }
  rm -f "$RAILWAY_DATA_DIR/railway.tar.gz"

  local found_bin
  found_bin=$(find "$RAILWAY_DATA_DIR" -name "railway" -type f 2>/dev/null | head -1)
  if [ -z "$found_bin" ]; then
    return 1
  fi

  chmod +x "$found_bin"
  ln -sf "$found_bin" "$PREFIX/bin/railway" 2>/dev/null

  return 0
}

install_railway() {
  if command -v railway &>/dev/null; then
    log_info "Railway CLI is already installed"
    return 2
  fi

  log_info "Installing Railway CLI..."

  mkdir -p "$(dirname "$LOG_FILE")" "$RAILWAY_DATA_DIR"

  if npm install -g @railway/cli --legacy-peer-deps &>>"$LOG_FILE"; then
    command -v termux-fix-shebang &>/dev/null && termux-fix-shebang "$(command -v railway 2>/dev/null)" &>/dev/null
    log_success "Railway CLI installed via npm"
    return 0
  fi

  log_warn "npm install failed for @railway/cli on Termux ARM"
  log_info "Trying manual ARM64 binary download..."

  if _install_railway_manual; then
    log_success "Railway CLI installed (ARM64 Linux binary)"
    return 0
  fi

  log_error "Railway CLI installation failed. Railway does not provide official ARM Linux builds."
  log_info "Workaround: use 'npx @railway/cli' instead of 'railway' command."
  log_info "Or install Railway on a cloud machine."
  return 1
}

uninstall_railway() {
  log_info "Uninstalling Railway CLI..."
  npm uninstall -g @railway/cli &>>"$LOG_FILE" 2>/dev/null || true
  rm -f "$PREFIX/bin/railway" 2>/dev/null
  rm -rf "$RAILWAY_DATA_DIR" 2>/dev/null
  log_success "Railway CLI uninstalled"
  return 0
}

update_railway() {
  _check_update_needed "Railway CLI" "$(_get_installed_npm_version @railway/cli)" "$(_get_remote_npm_version @railway/cli)" _do_update_railway
}

_do_update_railway() {
  npm update -g @railway/cli --legacy-peer-deps &>>"$LOG_FILE" || {
    log_warn "npm update failed"
    return 1
  }
  return 0
}

reinstall_railway() {
  uninstall_railway
  install_railway
}
