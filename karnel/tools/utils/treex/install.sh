#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_treex() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/treex"
  local BIN_NAME="treex"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Developer%20Base/Tree%20Explorer.py"
  if command -v treex &>/dev/null; then
    log_info "Tree Explorer is already installed"
    return 2
  fi
  log_info "Installing Tree Explorer..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "Tree Explorer installed"
  return 0
}

uninstall_treex() {
  local BIN_NAME="treex"
  local TOOL_DIR="$KARNEL_PATH/tools/utils/treex"
  if ! command -v treex &>/dev/null; then log_info "Tree Explorer is not installed"; return 2; fi
  log_info "Uninstalling Tree Explorer..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "Tree Explorer uninstalled"
  return 0
}

update_treex() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/treex"
  local BIN_NAME="treex"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Developer%20Base/Tree%20Explorer.py"
  log_info "Updating Tree Explorer..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "Tree Explorer updated"
  return 0
}

reinstall_treex() {
  uninstall_treex
  install_treex
}
