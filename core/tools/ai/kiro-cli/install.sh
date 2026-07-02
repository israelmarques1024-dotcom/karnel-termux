#!/data/data/com.termux/files/usr/bin/bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"
KIRO_DATA_DIR="$HOME/.local/share/omni-data/kiro-cli"

_kiro_cli_dependencies() {
  loading "Installing dependencies" _kiro_cli_dependencies_impl
}

_kiro_cli_dependencies_impl() {
  declare -A DEPS=(
    ["curl"]="curl"
    ["unzip"]="unzip"
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

_install_kiro_cli_curl() {
  loading "Installing Kiro CLI" _install_kiro_cli_curl_impl
}

_install_kiro_cli_curl_impl() {
  mkdir -p "$KIRO_DATA_DIR"

  local install_url="https://cli.kiro.dev/install"
  if ! curl -fsSL "$install_url" | bash &>>"$LOG_FILE"; then
    log_error "Failed to install Kiro CLI"
    return 1
  fi

  return 0
}

install_kiro_cli() {
  if command -v kiro &>/dev/null; then
    log_info "Kiro CLI is already installed"
    return 2
  fi

  log_info "Installing Kiro CLI..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _kiro_cli_dependencies || return 1
  _install_kiro_cli_curl || return 1

  log_success "Kiro CLI installed successfully"
  return 0
}

uninstall_kiro_cli() {
  if ! command -v kiro &>/dev/null; then
    log_info "Kiro CLI is not installed"
    return 2
  fi

  log_info "Uninstalling Kiro CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Removing Kiro CLI" _uninstall_kiro_cli_impl

  log_success "Kiro CLI uninstalled"
  return 0
}

_uninstall_kiro_cli_impl() {
  rm -f "$HOME/.local/bin/kiro" "$HOME/.local/bin/kiro-cli" 2>/dev/null
  rm -rf "$KIRO_DATA_DIR" 2>/dev/null
  return 0
}

update_kiro_cli() {
  if ! command -v kiro &>/dev/null; then
    log_error "Kiro CLI is not installed"
    return 1
  fi

  log_info "Updating Kiro CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Updating Kiro CLI" _update_kiro_cli_impl

  log_success "Kiro CLI updated"
  return 0
}

_update_kiro_cli_impl() {
  local install_url="https://cli.kiro.dev/install"
  if ! curl -fsSL "$install_url" | bash &>>"$LOG_FILE"; then
    log_error "Failed to update Kiro CLI"
    return 1
  fi
  return 0
}

reinstall_kiro_cli() {
  uninstall_kiro_cli
  install_kiro_cli
}
