#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_network.log"
DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Network%20Tools/Dark.py"

install_dark() {
  local TOOL_DIR="$KARNEL_PATH/tools/network/dark"
  local BIN_NAME="dark"
  if command -v dark &>/dev/null; then
    log_info "Dark Web OSINT is already installed"
    return 2
  fi
  log_info "Installing Dark Web OSINT (Tor crawler + scraper)..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi
  if ! command -v tor &>/dev/null; then pkg install tor -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "Dark Web OSINT installed"
  return 0
}

uninstall_dark() {
  local BIN_NAME="dark"
  local TOOL_DIR="$KARNEL_PATH/tools/network/dark"
  if ! command -v dark &>/dev/null; then log_info "Dark Web OSINT is not installed"; return 2; fi
  log_info "Uninstalling Dark Web OSINT..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "Dark Web OSINT uninstalled"
  return 0
}

update_dark() {
  local TOOL_DIR="$KARNEL_PATH/tools/network/dark"
  local BIN_NAME="dark"
  log_info "Updating Dark Web OSINT..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "Dark Web OSINT updated"
  return 0
}

reinstall_dark() {
  uninstall_dark
  install_dark
}
