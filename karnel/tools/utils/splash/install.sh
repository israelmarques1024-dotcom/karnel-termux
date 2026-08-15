#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_splash() {
  local TOOL_DIR="$KARNEL_DATA/utils/splash"
  local BIN_NAME="splash"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Other%20Tools/Loading%20Screen.py"
  log_info "Installing Loading Screen..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi
  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "Loading Screen installed"
  return 0
}

uninstall_splash() {
  local BIN_NAME="splash"
  local TOOL_DIR="$KARNEL_DATA/utils/splash"
  log_info "Uninstalling Loading Screen..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "Loading Screen uninstalled"
  return 0
}

update_splash() {
  local TOOL_DIR="$KARNEL_DATA/utils/splash"
  local BIN_NAME="splash"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Other%20Tools/Loading%20Screen.py"
  log_info "Updating Loading Screen..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "Loading Screen updated"
  return 0
}

reinstall_splash() {
  uninstall_splash
  install_splash
}
