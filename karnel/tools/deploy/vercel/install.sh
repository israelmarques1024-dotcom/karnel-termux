#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

VERCEL_BIN="$PREFIX/lib/node_modules/vercel/dist/vc.js"

install_vercel() {
  if [[ -f "$VERCEL_BIN" ]]; then
    log_info "Vercel CLI is already installed"
    return 2
  fi
  log_info "Installing Vercel CLI..."
  npm install -g vercel &>/dev/null || {
    log_error "Failed to install Vercel CLI"
    return 1
  }
  command -v termux-fix-shebang &>/dev/null && termux-fix-shebang "$(command -v vercel)" &>/dev/null
  log_success "Vercel CLI installed"
}

uninstall_vercel() {
  log_info "Uninstalling Vercel CLI..."
  npm uninstall -g vercel &>/dev/null || {
    log_error "Failed to uninstall Vercel CLI"
    return 1
  }
  log_success "Vercel CLI uninstalled"
}

update_vercel() {
  _check_update_needed "Vercel CLI" "$(_get_installed_npm_version vercel)" "$(_get_remote_npm_version vercel)" _do_update_vercel
}

_do_update_vercel() {
  npm update -g vercel &>/dev/null || {
    log_error "Failed to update Vercel CLI"
    return 1
  }
  command -v termux-fix-shebang &>/dev/null && termux-fix-shebang "$(command -v vercel)" &>/dev/null
  return 0
}

reinstall_vercel() {
  uninstall_vercel
  install_vercel
}
