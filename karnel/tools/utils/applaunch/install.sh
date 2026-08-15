#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_applaunch() {
  local TOOL_DIR="$KARNEL_DATA/utils/applaunch"
  local BIN_NAME="applaunch"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Other%20Tools/Android%20App%20Launcher.py"
  log_info "Installing App Launcher..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi
  pkg install termux-api -y &>>"$LOG_FILE" || true
  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "App Launcher installed"
  return 0
}

uninstall_applaunch() {
  local BIN_NAME="applaunch"
  local TOOL_DIR="$KARNEL_DATA/utils/applaunch"
  log_info "Uninstalling App Launcher..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "App Launcher uninstalled"
  return 0
}

update_applaunch() {
  local TOOL_DIR="$KARNEL_DATA/utils/applaunch"
  local BIN_NAME="applaunch"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Other%20Tools/Android%20App%20Launcher.py"
  log_info "Updating App Launcher..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "App Launcher updated"
  return 0
}

reinstall_applaunch() {
  uninstall_applaunch
  install_applaunch
}
