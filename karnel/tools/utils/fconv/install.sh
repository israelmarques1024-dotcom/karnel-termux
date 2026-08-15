#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_fconv() {
  local TOOL_DIR="$KARNEL_DATA/utils/fconv"
  local BIN_NAME="fconv"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Developer%20Base/File%20Converter.py"
  log_info "Installing File Converter..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi
  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "File Converter installed"
  return 0
}

uninstall_fconv() {
  local BIN_NAME="fconv"
  local TOOL_DIR="$KARNEL_DATA/utils/fconv"
  log_info "Uninstalling File Converter..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "File Converter uninstalled"
  return 0
}

update_fconv() {
  local TOOL_DIR="$KARNEL_DATA/utils/fconv"
  local BIN_NAME="fconv"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Developer%20Base/File%20Converter.py"
  log_info "Updating File Converter..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "File Converter updated"
  return 0
}

reinstall_fconv() {
  uninstall_fconv
  install_fconv
}
