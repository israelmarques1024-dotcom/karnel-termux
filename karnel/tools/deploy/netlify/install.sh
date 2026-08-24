#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

NETLIFY_VERSION="27.1.1"

_netlify_node_supported() {
  local version
  version="$(node --version 2>/dev/null | sed 's/^v//')"
  [[ -n "$version" ]] && [[ "$(printf '%s\n%s\n' '22.13.0' "$version" | sort -V | head -1)" == "22.13.0" ]]
}

install_netlify() {
  if command -v netlify &>/dev/null && netlify --version &>/dev/null; then
    log_info "Netlify CLI is already installed"
    return 2
  fi
  if ! command -v node &>/dev/null || ! command -v npm &>/dev/null; then
    log_info "Installing Node.js..."
    if ! pkg install -y nodejs-lts &>>"$LOG_FILE"; then
      log_error "Failed to install Node.js"
      return 1
    fi
  fi
	if ! _netlify_node_supported; then
		log_error "Netlify CLI requires Node.js 22.13.0 or newer. Update Node.js and retry."
		return 1
	fi
  log_info "Installing Netlify CLI..."
  npm install -g "netlify-cli@$NETLIFY_VERSION" &>/dev/null || {
    log_error "Failed to install Netlify CLI"
    return 1
  }
  command -v termux-fix-shebang &>/dev/null && termux-fix-shebang "$(command -v netlify)" &>/dev/null
	if ! netlify --version &>/dev/null; then
		log_error "Netlify CLI did not start after installation"
		return 1
	fi
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
