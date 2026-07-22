#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_applaunch() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/applaunch"
  local BIN_NAME="applaunch"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Other%20Tools/Android%20App%20Launcher.py"
  if command -v applaunch &>/dev/null; then
    log_info "App Launcher is already installed"
    return 2
  fi
  log_info "Installing App Launcher..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi
  pkg install termux-api -y &>>"$LOG_FILE" || true
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "App Launcher installed"
  return 0
}

uninstall_applaunch() {
  local BIN_NAME="applaunch"
  local TOOL_DIR="$KARNEL_PATH/tools/utils/applaunch"
  if ! command -v applaunch &>/dev/null; then log_info "App Launcher is not installed"; return 2; fi
  log_info "Uninstalling App Launcher..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "App Launcher uninstalled"
  return 0
}

update_applaunch() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/applaunch"
  local BIN_NAME="applaunch"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Other%20Tools/Android%20App%20Launcher.py"
  log_info "Updating App Launcher..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "App Launcher updated"
  return 0
}

reinstall_applaunch() {
  uninstall_applaunch
  install_applaunch
}
