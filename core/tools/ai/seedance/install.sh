#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

_seedance_dependencies() {
  loading "Installing dependencies" _seedance_dependencies_impl
}

_seedance_dependencies_impl() {
  declare -A DEPS=(
    ["python"]="python3"
    ["pip"]="pip"
  )

  local pkg_name bin_name
  for pkg_name in "${!DEPS[@]}"; do
    bin_name="${DEPS[$pkg_name]}"
    if ! command -v "$bin_name" &>/dev/null; then
      if ! pkg install "$pkg_name" -y &>>"$LOG_FILE"; then
        log_error "Failed to install $pkg_name"
        return 1
      fi
    fi
  done

  return 0
}

_install_seedance_pip() {
  loading "Installing Seedance CLI" _install_seedance_pip_impl
}

_install_seedance_pip_impl() {
  if ! pip install seedance-cli &>>"$LOG_FILE"; then
    log_error "Failed to install Seedance CLI"
    return 1
  fi
  return 0
}

install_seedance() {
  if pip show seedance-cli &>/dev/null; then
    log_info "Seedance CLI is already installed"
    return 2
  fi

  log_info "Installing Seedance CLI..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _seedance_dependencies || return 1
  _install_seedance_pip || return 1

  log_success "Seedance CLI installed successfully"
  return 0
}

uninstall_seedance() {
  if ! pip show seedance-cli &>/dev/null; then
    log_info "Seedance CLI is not installed"
    return 2
  fi

  log_info "Uninstalling Seedance CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Removing Seedance CLI" _uninstall_seedance_impl

  log_success "Seedance CLI uninstalled"
  return 0
}

_uninstall_seedance_impl() {
  if ! pip uninstall seedance-cli -y &>>"$LOG_FILE"; then
    log_error "Failed to uninstall Seedance CLI"
    return 1
  fi
  return 0
}

update_seedance() {
  if ! pip show seedance-cli &>/dev/null; then
    log_error "Seedance CLI is not installed"
    return 1
  fi

  log_info "Updating Seedance CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Updating Seedance CLI" _update_seedance_impl

  log_success "Seedance CLI updated"
  return 0
}

_update_seedance_impl() {
  if ! pip install --upgrade seedance-cli &>>"$LOG_FILE"; then
    log_error "Failed to update Seedance CLI"
    return 1
  fi
  return 0
}

reinstall_seedance() {
  uninstall_seedance
  install_seedance
}
