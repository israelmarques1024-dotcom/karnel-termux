#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_notes.log"

install_notes() {
  local TOOL_DIR="$KARNEL_DATA/utils/notes"
  local BIN_NAME="notes"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Developer%20Base/Smart%20Notes.py"
  log_info "Installing Smart Notes..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi
  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "Smart Notes installed"
  return 0
}

uninstall_notes() {
  local BIN_NAME="notes"
  local TOOL_DIR="$KARNEL_DATA/utils/notes"
  log_info "Uninstalling Smart Notes..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "Smart Notes uninstalled"
  return 0
}

update_notes() {
  local TOOL_DIR="$KARNEL_DATA/utils/notes"
  local BIN_NAME="notes"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Developer%20Base/Smart%20Notes.py"
  log_info "Updating Smart Notes..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "Smart Notes updated"
  return 0
}

reinstall_notes() {
  uninstall_notes
  install_notes
}
