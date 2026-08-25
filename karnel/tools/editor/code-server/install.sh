#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="${LOG_FILE:-${KARNEL_CACHE:-$HOME/.cache/karnel}/install_editor.log}"

# code-server - VS Code in the browser for Termux
# Official docs: https://coder.com/docs/code-server
# Termux install: pkg install tur-repo && pkg install code-server

CODE_SERVER_PASSWORD="$(head -c 16 /dev/urandom | base64 | tr -d '/+=' | head -c 16)"

install_code_server() {
  if command -v code-server &>/dev/null; then
    log_info "code-server is already installed"
    return 2
  fi

  log_info "Installing code-server (VS Code for Termux)..."

  mkdir -p "$(dirname "$LOG_FILE")"

  # Add tur-repo if not present (required for code-server on Termux)
  if ! pkg list-installed 2>/dev/null | grep -q tur-repo; then
    log_info "Adding tur-repo (required for code-server)..."
    if ! pkg install -y tur-repo &>>"$LOG_FILE"; then
      log_error "Failed to add tur-repo (see $LOG_FILE)"
      return 1
    fi
  fi

  if ! pkg update -y &>>"$LOG_FILE"; then
    log_error "Failed to refresh package lists (see $LOG_FILE)"
    return 1
  fi

  if pkg install -y code-server &>>"$LOG_FILE" && command -v code-server &>/dev/null; then
    # Do not replace a user-managed configuration or its password.
    mkdir -p "$HOME/.config/code-server"
    chmod 700 "$HOME/.config/code-server"
    if [[ ! -f "$HOME/.config/code-server/config.yaml" ]]; then
      cat > "$HOME/.config/code-server/config.yaml" << CONF
bind-addr: 127.0.0.1:8080
auth: password
password: ${CODE_SERVER_PASSWORD}
cert: false
CONF
      chmod 600 "$HOME/.config/code-server/config.yaml"
    else
      log_info "Keeping existing code-server configuration"
    fi
    log_success "code-server installed successfully"
    log_info "Run: code-server"
    log_info "Then open http://localhost:8080 in your browser"
    log_info "The generated password is stored in ~/.config/code-server/config.yaml (chmod 600)"
    return 0
  else
    log_error "code-server installation failed (see $LOG_FILE)"
    return 1
  fi
}

uninstall_code_server() {
  if ! command -v code-server &>/dev/null; then
    log_info "code-server is not installed"
    return 0
  fi

  log_info "Uninstalling code-server..."
  if ! pkg uninstall -y code-server &>>"$LOG_FILE"; then
    log_error "Failed to uninstall code-server (see $LOG_FILE)"
    return 1
  fi
  return 0
}

update_code_server() {
  if ! command -v code-server &>/dev/null; then
    log_warn "code-server is not installed"
    return 1
  fi

  _check_update_needed "code-server" "$(_get_installed_pkg_version code-server)" "$(_get_remote_pkg_version code-server)" _update_code_server_impl
}

_update_code_server_impl() {
  if ! pkg upgrade -y code-server &>>"$LOG_FILE"; then
    log_error "Falha ao atualizar code-server"
    return 1
  fi
}

reinstall_code_server() {
  uninstall_code_server
  install_code_server
  return $?
}
