#!/usr/bin/env bash

# openspec - Spec-Driven Development framework for AI workflow orchestration
# Bridges human intent and AI output with structured technical specs
# Stores specs in /openspec/ directory to guide AI agents
# Official: npm install -g @fission-ai/openspec@latest

install_openspec() {
  if command -v openspec &>/dev/null; then
    log_info "openspec is already installed"
    return 2
  fi

  log_info "Installing openspec (Spec-Driven Development framework)..."
  npm install -g @fission-ai/openspec@latest 2>/dev/null
  local rc=$?

  if [[ $rc -eq 0 ]] && command -v openspec &>/dev/null; then
    log_success "openspec installed successfully"
    log_info "Run: openspec init to create /openspec/ directory"
    return 0
  else
    log_error "openspec installation failed"
    return 1
  fi
}

uninstall_openspec() {
  if ! command -v openspec &>/dev/null; then
    log_info "openspec is not installed"
    return 0
  fi

  log_info "Uninstalling openspec..."
  npm uninstall -g @fission-ai/openspec 2>/dev/null
  return $?
}

update_openspec() {
  if ! command -v openspec &>/dev/null; then
    log_warn "openspec is not installed"
    return 1
  fi

  log_info "Updating openspec..."
  npm update -g @fission-ai/openspec 2>/dev/null
  return $?
}

reinstall_openspec() {
  uninstall_openspec 2>/dev/null
  install_openspec
  return $?
}
