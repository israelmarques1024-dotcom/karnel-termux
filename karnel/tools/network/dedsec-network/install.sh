#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_network.log"
DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Network%20Tools/DedSec%27s%20Network.py"

install_dedsec_network() {
  local TOOL_DIR="$KARNEL_PATH/tools/network/dedsec-network"
  local BIN_NAME="dedsec-network"
  if command -v dedsec-network &>/dev/null; then
    log_info "DedSec Network Toolkit is already installed"
    return 2
  fi
  log_info "Installing DedSec Network Toolkit (scanner + OSINT + pentest)..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "DedSec Network Toolkit installed"
  return 0
}

uninstall_dedsec_network() {
  local BIN_NAME="dedsec-network"
  local TOOL_DIR="$KARNEL_PATH/tools/network/dedsec-network"
  if ! command -v dedsec-network &>/dev/null; then log_info "DedSec Network Toolkit is not installed"; return 2; fi
  log_info "Uninstalling DedSec Network Toolkit..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "DedSec Network Toolkit uninstalled"
  return 0
}

update_dedsec_network() {
  local TOOL_DIR="$KARNEL_PATH/tools/network/dedsec-network"
  local BIN_NAME="dedsec-network"
  log_info "Updating DedSec Network Toolkit..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "DedSec Network Toolkit updated"
  return 0
}

reinstall_dedsec_network() {
  uninstall_dedsec_network
  install_dedsec_network
}
