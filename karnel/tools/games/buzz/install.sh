#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_buzz() {
  local TOOL_DIR="$KARNEL_DATA/games/buzz"
  local BIN_NAME="buzz"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Games/Buzz.py"
  log_info "Installing Buzz..."
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi
  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "Buzz installed"
  return 0
}

uninstall_buzz() {
  local BIN_NAME="buzz"
  local TOOL_DIR="$KARNEL_DATA/games/buzz"
  log_info "Uninstalling Buzz..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "Buzz uninstalled"
  return 0
}

update_buzz() {
  local TOOL_DIR="$KARNEL_DATA/games/buzz"
  local BIN_NAME="buzz"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Games/Buzz.py"
  log_info "Updating Buzz..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "Buzz updated"
  return 0
}

reinstall_buzz() {
  uninstall_buzz
  install_buzz
}
