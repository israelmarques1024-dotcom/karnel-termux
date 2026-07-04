#!/usr/bin/env bash

import "@/utils/log"

install_railway() {
  if command -v railway &>/dev/null; then
    log_info "Railway CLI is already installed"
    return 2
  fi
  log_info "Installing Railway CLI..."
  npm install -g @railway/cli --legacy-peer-deps &>/dev/null || {
    log_warn "npm install failed, trying with npx..."
    npx -y @railway/cli --version &>/dev/null || {
      log_error "Failed to install Railway CLI"
      return 1
    }
  }
  command -v termux-fix-shebang &>/dev/null && termux-fix-shebang "$(command -v railway 2>/dev/null)" &>/dev/null
  log_success "Railway CLI installed"
}

uninstall_railway() {
  log_info "Uninstalling Railway CLI..."
  npm uninstall -g @railway/cli &>/dev/null || {
    log_error "Failed to uninstall Railway CLI"
    return 1
  }
  log_success "Railway CLI uninstalled"
}

update_railway() {
  log_info "Updating Railway CLI..."
  npm update -g @railway/cli &>/dev/null || {
    log_warn "npm update failed, trying reinstall..."
    npm install -g @railway/cli --legacy-peer-deps &>/dev/null || {
      log_error "Failed to update Railway CLI"
      return 1
    }
  }
  command -v termux-fix-shebang &>/dev/null && termux-fix-shebang "$(command -v railway 2>/dev/null)" &>/dev/null
  log_success "Railway CLI updated"
}

reinstall_railway() {
  uninstall_railway
  install_railway
}
