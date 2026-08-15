#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_websites() {
  local TOOL_DIR="$KARNEL_DATA/utils/websites"
  local BIN_NAME="websites"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Developer%20Base/Simple%20Websites%20Creator.py"
  log_info "Installing Websites Creator..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi
  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "Websites Creator installed"
  return 0
}

uninstall_websites() {
  local BIN_NAME="websites"
  local TOOL_DIR="$KARNEL_DATA/utils/websites"
  log_info "Uninstalling Websites Creator..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "Websites Creator uninstalled"
  return 0
}

update_websites() {
  local TOOL_DIR="$KARNEL_DATA/utils/websites"
  local BIN_NAME="websites"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Developer%20Base/Simple%20Websites%20Creator.py"
  log_info "Updating Websites Creator..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "Websites Creator updated"
  return 0
}

reinstall_websites() {
  uninstall_websites
  install_websites
}
