#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_dev.log"
DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Network%20Tools/QR%20Code%20Generator.py"

install_qrcode() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/qrcode"
  local BIN_NAME="qrcode"
  if command -v qrcode &>/dev/null; then
    log_info "QR Code Generator is already installed"
    return 2
  fi
  log_info "Installing QR Code Generator..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "QR Code Generator installed"
  return 0
}

uninstall_qrcode() {
  local BIN_NAME="qrcode"
  local TOOL_DIR="$KARNEL_PATH/tools/utils/qrcode"
  if ! command -v qrcode &>/dev/null; then log_info "QR Code Generator is not installed"; return 2; fi
  log_info "Uninstalling QR Code Generator..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "QR Code Generator uninstalled"
  return 0
}

update_qrcode() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/qrcode"
  local BIN_NAME="qrcode"
  log_info "Updating QR Code Generator..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "QR Code Generator updated"
  return 0
}

reinstall_qrcode() {
  uninstall_qrcode
  install_qrcode
}
