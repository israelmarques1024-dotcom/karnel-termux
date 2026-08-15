#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_filecheck() {
  local TOOL_DIR="$KARNEL_DATA/utils/filecheck"
  local BIN_NAME="filecheck"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Developer%20Base/File%20Type%20Checker.py"
  log_info "Installing File Checker..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi
  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "File Checker installed"
  return 0
}

uninstall_filecheck() {
  local BIN_NAME="filecheck"
  local TOOL_DIR="$KARNEL_DATA/utils/filecheck"
  log_info "Uninstalling File Checker..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "File Checker uninstalled"
  return 0
}

update_filecheck() {
  local TOOL_DIR="$KARNEL_DATA/utils/filecheck"
  local BIN_NAME="filecheck"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Developer%20Base/File%20Type%20Checker.py"
  log_info "Updating File Checker..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "File Checker updated"
  return 0
}

reinstall_filecheck() {
  uninstall_filecheck
  install_filecheck
}
