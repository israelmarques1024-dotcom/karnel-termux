#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

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
  _check_update_needed "Netlify CLI" "$(_get_installed_npm_version netlify-cli)" "$(_get_remote_npm_version netlify-cli)" _do_update_netlify
}

_do_update_netlify() {
  npm update -g netlify-cli &>/dev/null || {
    log_error "Failed to update Netlify CLI"
    return 1
  }
  command -v termux-fix-shebang &>/dev/null && termux-fix-shebang "$(command -v netlify)" &>/dev/null
  return 0
}

reinstall_netlify() {
  uninstall_netlify
  install_netlify
}
