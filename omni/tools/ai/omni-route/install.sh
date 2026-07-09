#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

install_omni_route() {
  if command -v omni-route &>/dev/null; then
    log_info "omniRoute already installed"
    return 2
  fi

  log_info "Installing omniRoute..."

  if ! command -v npm &>/dev/null; then
    log_error "npm is not installed. Run: omni install lang --nodejs"
    return 1
  fi

  if npm i -g omniroute 2>>"$LOG_FILE"; then
    if command -v omni-route &>/dev/null; then
      log_success "omniRoute installed successfully"
      return 0
    fi
  fi

  # Fallback: npx
  log_warn "npm install failed, trying npx..."
  if npx -y omniroute --version &>/dev/null; then
    log_success "omniRoute available via npx"
    return 0
  fi

  log_error "Failed to install omniRoute"
  return 1
}

uninstall_omni_route() {
  if ! command -v omni-route &>/dev/null; then
    log_info "omniRoute is not installed"
    return 0
  fi

  log_info "Uninstalling omniRoute..."
  npm uninstall -g omniroute 2>>"$LOG_FILE" || true
  rm -f "$PREFIX/bin/omni-route"
  log_success "omniRoute uninstalled"
  return 0
}

update_omni_route() {
  if ! command -v omni-route &>/dev/null; then
    log_info "omniRoute is not installed"
    return 0
  fi

  log_info "Updating omniRoute..."
  if npm i -g omniroute@latest 2>>"$LOG_FILE"; then
    log_success "omniRoute updated"
    return 0
  else
    log_error "Failed to update omniRoute"
    return 1
  fi
}

reinstall_omni_route() {
  uninstall_omni_route
  install_omni_route
}
