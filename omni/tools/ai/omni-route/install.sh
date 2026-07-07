#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

_install_omni_route_impl() {
  if ! command -v npm &>/dev/null; then
    pkg install nodejs -y &>>"$LOG_FILE" || log_error "Failed to install Node.js"
  fi
  
  npm install -g omniroute@latest &>>"$LOG_FILE" && log_success "omniRoute installed (npm)" || log_error "Failed to install omniRoute"
}

install_omni_route() {
  if command -v omniroute &>/dev/null; then
    log_info "omniRoute already installed"
    return 2
  fi
  log_info "Installing omniRoute (AI gateway)..."
  _install_omni_route_impl
}

uninstall_omni_route() {
  npm uninstall -g omniroute 2>/dev/null || true
  log_success "omniRoute uninstalled"
}

update_omni_route() {
  log_info "Updating omniRoute..."
  npm update -g omniroute 2>&1 &>>"$LOG_FILE" && log_success "omniRoute updated" || log_error "Failed to update omniRoute"
}

reinstall_omni_route() {
  uninstall_omni_route
  install_omni_route
}