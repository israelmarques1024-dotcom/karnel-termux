#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

_kimchi_dependencies() {
  loading "Installing dependencies" _kimchi_dependencies_impl
}

_kimchi_dependencies_impl() {
  declare -A DEPS=(
    ["nodejs-lts"]="node"
    ["git"]="git"
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

_install_kimchi_npm() {
  loading "Installing Kimchi AI" _install_kimchi_npm_impl
}

_install_kimchi_npm_impl() {
  if ! npm install -g @kimchi-ai/cli &>>"$LOG_FILE"; then
    log_error "Failed to install Kimchi AI"
    return 1
  fi
  return 0
}

install_kimchi_code() {
  if command -v kimchi &>/dev/null; then
    log_info "Kimchi AI is already installed"
    return 2
  fi

  log_info "Installing Kimchi AI..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _kimchi_dependencies || return 1
  _install_kimchi_npm || return 1

  log_success "Kimchi AI installed successfully"
  return 0
}

uninstall_kimchi_code() {
  if ! command -v kimchi &>/dev/null; then
    log_success "Kimchi AI is not installed"
    return 2
  fi

  log_info "Uninstalling Kimchi AI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Removing Kimchi AI" _uninstall_kimchi_impl
  log_success "Kimchi AI uninstalled successfully"
  return 0
}

_uninstall_kimchi_impl() {
  npm uninstall -g @kimchi-ai/cli &>>"$LOG_FILE"
}

update_kimchi_code() {
  if ! command -v kimchi &>/dev/null; then
    log_error "Kimchi AI is not installed"
    return 1
  fi
  log_info "Updating Kimchi AI..."
  mkdir -p "$(dirname "$LOG_FILE")"
  loading "Updating Kimchi AI" _update_kimchi_impl
  log_success "Kimchi AI updated successfully"
  return 0
}

_update_kimchi_impl() {
  npm update -g @kimchi-ai/cli &>>"$LOG_FILE"
}

reinstall_kimchi_code() {
  uninstall_kimchi_code
  install_kimchi_code
}
