#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_passman() {
  local TOOL_DIR="$KARNEL_PATH/tools/dev/passman"
  local BIN_NAME="passman"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Other%20Tools/Password%20Master.py"
  if command -v passman &>/dev/null; then
    log_info "Password Master is already installed"
    return 2
  fi
  log_info "Installing Password Master..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "Password Master installed"
  return 0
}

uninstall_passman() {
  local BIN_NAME="passman"
  local TOOL_DIR="$KARNEL_PATH/tools/dev/passman"
  if ! command -v passman &>/dev/null; then log_info "Password Master is not installed"; return 2; fi
  log_info "Uninstalling Password Master..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "Password Master uninstalled"
  return 0
}

update_passman() {
  local TOOL_DIR="$KARNEL_PATH/tools/dev/passman"
  local BIN_NAME="passman"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Other%20Tools/Password%20Master.py"
  log_info "Updating Password Master..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "Password Master updated"
  return 0
}

reinstall_passman() {
  uninstall_passman
  install_passman
}
