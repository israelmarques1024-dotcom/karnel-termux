#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_ai.log"

install_copilot_termux() {
  if command -v copilot &>/dev/null; then
    log_info "Copilot-Termux is already installed"
    return 2
  fi

  log_info "Installing Copilot-Termux..."
  mkdir -p "$(dirname "$LOG_FILE")"

  if ! command -v npm &>/dev/null; then
    log_error "npm is required. Install Node.js first: karnel install lang --nodejs"
    return 1
  fi

  if ! npm install -g @bash0816/copilot-termux &>>"$LOG_FILE"; then
    log_error "Failed to install Copilot-Termux via npm"
    return 1
  fi

  hash -r 2>/dev/null || true

  if ! command -v copilot &>/dev/null; then
    log_error "Copilot-Termux installed but binary not on PATH"
    log_info "Try: hash -r; copilot --help"
    return 1
  fi

  log_success "Copilot-Termux installed"
  log_info "Run: copilot -p \"your question\""
  return 0
}

uninstall_copilot_termux() {
  if ! command -v copilot &>/dev/null; then
    log_info "Copilot-Termux is not installed"
    return 2
  fi

  log_info "Uninstalling Copilot-Termux..."
  mkdir -p "$(dirname "$LOG_FILE")"

  if npm uninstall -g @bash0816/copilot-termux &>>"$LOG_FILE"; then
    log_success "Copilot-Termux uninstalled"
    return 0
  else
    log_error "Failed to uninstall Copilot-Termux"
    return 1
  fi
}

update_copilot_termux() {
  _check_update_needed "Copilot-Termux" \
    "$(_get_installed_npm_version @bash0816/copilot-termux)" \
    "$(_get_remote_npm_version @bash0816/copilot-termux)" \
    _do_update_copilot_termux
}

_do_update_copilot_termux() {
  log_info "Updating Copilot-Termux..."

  if npm update -g @bash0816/copilot-termux &>>"$LOG_FILE"; then
    log_success "Copilot-Termux updated"
    return 0
  else
    log_error "Failed to update Copilot-Termux"
    return 1
  fi
}

reinstall_copilot_termux() {
  uninstall_copilot_termux
  install_copilot_termux
}
