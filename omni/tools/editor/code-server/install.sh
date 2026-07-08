#!/usr/bin/env bash

# code-server - VS Code in the browser for Termux
# Official docs: https://coder.com/docs/code-server
# Termux install: pkg install tur-repo && pkg install code-server

CODE_SERVER_PASSWORD="12092013iI@"

install_code_server() {
  if command -v code-server &>/dev/null; then
    log_info "code-server is already installed"
    return 2
  fi

  log_info "Installing code-server (VS Code for Termux)..."

  # Add tur-repo if not present (required for code-server on Termux)
  if ! pkg list-installed 2>/dev/null | grep -q tur-repo; then
    log_info "Adding tur-repo (required for code-server)..."
    pkg install -y tur-repo 2>/dev/null
  fi

  pkg install -y code-server 2>/dev/null
  local rc=$?

  if [[ $rc -eq 0 ]] && command -v code-server &>/dev/null; then
    # Configure code-server with password
    mkdir -p "$HOME/.config/code-server"
    cat > "$HOME/.config/code-server/config.yaml" << CONF
bind-addr: 0.0.0.0:8080
auth: password
password: ${CODE_SERVER_PASSWORD}
cert: false
CONF
    log_success "code-server installed successfully"
    log_info "Password: ${CODE_SERVER_PASSWORD}"
    log_info "Run: code-server"
    log_info "Then open http://localhost:8080 in your browser"
    return 0
  else
    log_error "code-server installation failed"
    return 1
  fi
}

uninstall_code_server() {
  if ! command -v code-server &>/dev/null; then
    log_info "code-server is not installed"
    return 0
  fi

  log_info "Uninstalling code-server..."
  pkg uninstall -y code-server 2>/dev/null
  return $?
}

update_code_server() {
  if ! command -v code-server &>/dev/null; then
    log_warn "code-server is not installed"
    return 1
  fi

  log_info "Updating code-server..."
  pkg upgrade -y code-server 2>/dev/null
  return $?
}

reinstall_code_server() {
  uninstall_code_server 2>/dev/null
  install_code_server
  return $?
}
