#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

_veo3_dependencies() {
  loading "Installing dependencies" _veo3_dependencies_impl
}

_veo3_dependencies_impl() {
  if ! command -v python3 &>/dev/null; then
    if ! pkg install python -y &>>"$LOG_FILE"; then
      log_error "Failed to install python"
      return 1
    fi
  fi

  if ! command -v pip &>/dev/null && ! python3 -m pip --version &>/dev/null; then
    python3 -m ensurepip --upgrade &>>"$LOG_FILE" 2>/dev/null || true
  fi

  return 0
}

_install_veo3_python() {
  loading "Installing Veo 3 SDK" _install_veo3_python_impl
}

_install_veo3_python_impl() {
  local pip_cmd
  if command -v pip &>/dev/null; then
    pip_cmd="pip"
  else
    pip_cmd="python3 -m pip"
  fi

  if ! $pip_cmd install google-genai &>>"$LOG_FILE"; then
    log_warn "google-genai pip install failed - package may not exist for this platform"
    log_warn "Veo 3 SDK requires: pip install google-genai (manual)"
    return 0
  fi
  return 0
}

install_veo3() {
  local pip_cmd
  if command -v pip &>/dev/null; then
    pip_cmd="pip"
  else
    pip_cmd="python3 -m pip"
  fi

  if $pip_cmd show google-genai &>/dev/null 2>&1; then
    log_info "Veo 3 SDK is already installed"
    return 2
  fi

  log_info "Installing Veo 3 SDK..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _veo3_dependencies || return 1
  _install_veo3_python || return 1

  log_success "Veo 3 SDK installed successfully"
  log_info "Authenticate with: gcloud auth application-default login"
  return 0
}

_veo3_pip_cmd() {
  if command -v pip &>/dev/null; then
    echo "pip"
  else
    echo "python3 -m pip"
  fi
}

uninstall_veo3() {
  local pip_cmd; pip_cmd="$(_veo3_pip_cmd)"
  if ! $pip_cmd show google-genai &>/dev/null 2>&1; then
    log_info "Veo 3 SDK is not installed"
    return 2
  fi

  log_info "Uninstalling Veo 3 SDK..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Removing Veo 3 SDK" _uninstall_veo3_impl

  log_success "Veo 3 SDK uninstalled"
  return 0
}

_uninstall_veo3_impl() {
  local pip_cmd; pip_cmd="$(_veo3_pip_cmd)"
  if ! $pip_cmd uninstall google-genai -y &>>"$LOG_FILE"; then
    log_error "Failed to uninstall Veo 3 SDK"
    return 1
  fi
  return 0
}

update_veo3() {
  local pip_cmd; pip_cmd="$(_veo3_pip_cmd)"
  if ! $pip_cmd show google-genai &>/dev/null 2>&1; then
    log_error "Veo 3 SDK is not installed"
    return 1
  fi

  log_info "Updating Veo 3 SDK..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Updating Veo 3 SDK" _update_veo3_impl

  log_success "Veo 3 SDK updated"
  return 0
}

_update_veo3_impl() {
  local pip_cmd; pip_cmd="$(_veo3_pip_cmd)"
  if ! $pip_cmd install --upgrade google-genai &>>"$LOG_FILE"; then
    log_warn "Failed to update google-genai"
    return 0
  fi
  return 0
}

reinstall_veo3() {
  uninstall_veo3
  install_veo3
}
