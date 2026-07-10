#!/usr/bin/env bash

import "@/utils/log"

install_netlify() {
  if command -v netlify &>/dev/null; then
    log_info "Netlify CLI is already installed"
    return 2
  fi
  log_info "Installing Netlify CLI..."
  npm install -g netlify-cli &>/dev/null || {
    log_error "Failed to install Netlify CLI"
    return 1
  }
  command -v termux-fix-shebang &>/dev/null && termux-fix-shebang "$(command -v netlify)" &>/dev/null
  log_success "Netlify CLI installed"
}

uninstall_netlify() {
  log_info "Uninstalling Netlify CLI..."
  npm uninstall -g netlify-cli &>/dev/null || {
    log_error "Failed to uninstall Netlify CLI"
    return 1
  }
  log_success "Netlify CLI uninstalled"
}

update_netlify() {
  log_info "Updating Netlify CLI..."
  npm update -g netlify-cli &>/dev/null || {
    log_error "Failed to update Netlify CLI"
    return 1
  }
  command -v termux-fix-shebang &>/dev/null && termux-fix-shebang "$(command -v netlify)" &>/dev/null
  log_success "Netlify CLI updated"
}

reinstall_netlify() {
  uninstall_netlify
  install_netlify
}
