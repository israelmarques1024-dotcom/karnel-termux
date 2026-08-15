#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_treex() {
  local TOOL_DIR="$KARNEL_DATA/utils/treex"
  local BIN_NAME="treex"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Developer%20Base/Tree%20Explorer.py"
  log_info "Installing Tree Explorer..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi
  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "Tree Explorer installed"
  return 0
}

uninstall_treex() {
  local BIN_NAME="treex"
  local TOOL_DIR="$KARNEL_DATA/utils/treex"
  log_info "Uninstalling Tree Explorer..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "Tree Explorer uninstalled"
  return 0
}

update_treex() {
  local TOOL_DIR="$KARNEL_DATA/utils/treex"
  local BIN_NAME="treex"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Developer%20Base/Tree%20Explorer.py"
  log_info "Updating Tree Explorer..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "Tree Explorer updated"
  return 0
}

reinstall_treex() {
  uninstall_treex
  install_treex
}
