#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_dev.log"
DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Network%20Tools/QR%20Code%20Generator.py"

install_qrcode() {
  local TOOL_DIR="$KARNEL_DATA/utils/qrcode"
  local BIN_NAME="qrcode"
  log_info "Installing QR Code Generator..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi
  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "QR Code Generator installed"
  return 0
}

uninstall_qrcode() {
  local BIN_NAME="qrcode"
  local TOOL_DIR="$KARNEL_DATA/utils/qrcode"
  log_info "Uninstalling QR Code Generator..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "QR Code Generator uninstalled"
  return 0
}

update_qrcode() {
  local TOOL_DIR="$KARNEL_DATA/utils/qrcode"
  local BIN_NAME="qrcode"
  log_info "Updating QR Code Generator..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "QR Code Generator updated"
  return 0
}

reinstall_qrcode() {
  uninstall_qrcode
  install_qrcode
}
