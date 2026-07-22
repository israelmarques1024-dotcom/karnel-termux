#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_filecheck() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/filecheck"
  local BIN_NAME="filecheck"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Developer%20Base/File%20Type%20Checker.py"
  if command -v filecheck &>/dev/null; then
    log_info "File Checker is already installed"
    return 2
  fi
  log_info "Installing File Checker..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "File Checker installed"
  return 0
}

uninstall_filecheck() {
  local BIN_NAME="filecheck"
  local TOOL_DIR="$KARNEL_PATH/tools/utils/filecheck"
  if ! command -v filecheck &>/dev/null; then log_info "File Checker is not installed"; return 2; fi
  log_info "Uninstalling File Checker..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "File Checker uninstalled"
  return 0
}

update_filecheck() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/filecheck"
  local BIN_NAME="filecheck"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Developer%20Base/File%20Type%20Checker.py"
  log_info "Updating File Checker..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "File Checker updated"
  return 0
}

reinstall_filecheck() {
  uninstall_filecheck
  install_filecheck
}
