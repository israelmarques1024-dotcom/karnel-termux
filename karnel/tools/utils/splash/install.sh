#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_splash() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/splash"
  local BIN_NAME="splash"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Other%20Tools/Loading%20Screen.py"
  if command -v splash &>/dev/null; then
    log_info "Loading Screen is already installed"
    return 2
  fi
  log_info "Installing Loading Screen..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "Loading Screen installed"
  return 0
}

uninstall_splash() {
  local BIN_NAME="splash"
  local TOOL_DIR="$KARNEL_PATH/tools/utils/splash"
  if ! command -v splash &>/dev/null; then log_info "Loading Screen is not installed"; return 2; fi
  log_info "Uninstalling Loading Screen..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "Loading Screen uninstalled"
  return 0
}

update_splash() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/splash"
  local BIN_NAME="splash"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Other%20Tools/Loading%20Screen.py"
  log_info "Updating Loading Screen..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "Loading Screen updated"
  return 0
}

reinstall_splash() {
  uninstall_splash
  install_splash
}
