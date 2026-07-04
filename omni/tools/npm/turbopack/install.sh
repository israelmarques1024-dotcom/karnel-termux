#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_npm.log"

install_turbopack() {
  if command -v turbo &>/dev/null; then
    log_info "Turbopack is already installed"
    return 2
  fi
  log_info "Installing Turbopack..."
  npm install -g turbo &>>"$LOG_FILE" || {
    log_error "Failed to install Turbopack"
    return 1
  }
  log_success "Turbopack installed"
}

uninstall_turbopack() {
  log_info "Uninstalling Turbopack..."
  npm uninstall -g turbo &>>"$LOG_FILE" || {
    log_error "Failed to uninstall Turbopack"
    return 1
  }
  log_success "Turbopack uninstalled"
}

update_turbopack() {
  log_info "Updating Turbopack..."
  npm update -g turbo &>>"$LOG_FILE" || {
    log_error "Failed to update Turbopack"
    return 1
  }
  log_success "Turbopack updated"
}

reinstall_turbopack() {
  uninstall_turbopack
  install_turbopack
}
