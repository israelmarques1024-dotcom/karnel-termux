#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_notes() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/notes"
  local BIN_NAME="notes"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Developer%20Base/Smart%20Notes.py"
  if command -v notes &>/dev/null; then
    log_info "Smart Notes is already installed"
    return 2
  fi
  log_info "Installing Smart Notes..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "Smart Notes installed"
  return 0
}

uninstall_notes() {
  local BIN_NAME="notes"
  local TOOL_DIR="$KARNEL_PATH/tools/utils/notes"
  if ! command -v notes &>/dev/null; then log_info "Smart Notes is not installed"; return 2; fi
  log_info "Uninstalling Smart Notes..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "Smart Notes uninstalled"
  return 0
}

update_notes() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/notes"
  local BIN_NAME="notes"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Developer%20Base/Smart%20Notes.py"
  log_info "Updating Smart Notes..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "Smart Notes updated"
  return 0
}

reinstall_notes() {
  uninstall_notes
  install_notes
}
