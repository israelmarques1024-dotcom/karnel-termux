#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_passman() {
  local TOOL_DIR="$KARNEL_DATA/utils/passman"
  local BIN_NAME="passman"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Other%20Tools/Password%20Master.py"
  log_info "Installing Password Master..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi
  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "Password Master installed"
  return 0
}

uninstall_passman() {
  local BIN_NAME="passman"
  local TOOL_DIR="$KARNEL_DATA/utils/passman"
  log_info "Uninstalling Password Master..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "Password Master uninstalled"
  return 0
}

update_passman() {
  local TOOL_DIR="$KARNEL_DATA/utils/passman"
  local BIN_NAME="passman"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Other%20Tools/Password%20Master.py"
  log_info "Updating Password Master..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "Password Master updated"
  return 0
}

reinstall_passman() {
  uninstall_passman
  install_passman
}
