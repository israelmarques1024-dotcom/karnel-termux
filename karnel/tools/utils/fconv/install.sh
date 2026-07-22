#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_fconv() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/fconv"
  local BIN_NAME="fconv"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Developer%20Base/File%20Converter.py"
  if command -v fconv &>/dev/null; then
    log_info "File Converter is already installed"
    return 2
  fi
  log_info "Installing File Converter..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "File Converter installed"
  return 0
}

uninstall_fconv() {
  local BIN_NAME="fconv"
  local TOOL_DIR="$KARNEL_PATH/tools/utils/fconv"
  if ! command -v fconv &>/dev/null; then log_info "File Converter is not installed"; return 2; fi
  log_info "Uninstalling File Converter..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "File Converter uninstalled"
  return 0
}

update_fconv() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/fconv"
  local BIN_NAME="fconv"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Developer%20Base/File%20Converter.py"
  log_info "Updating File Converter..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "File Converter updated"
  return 0
}

reinstall_fconv() {
  uninstall_fconv
  install_fconv
}
