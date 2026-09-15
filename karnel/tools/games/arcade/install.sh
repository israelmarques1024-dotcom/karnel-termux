#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_arcade() {
  local TOOL_DIR="$KARNEL_DATA/games/arcade"
  local BIN_NAME="arcade"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Games/Terminal%20Arcade.py"
  log_info "Installing Terminal Arcade..."
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "Terminal Arcade installed"
  return 0
}

uninstall_arcade() {
  local BIN_NAME="arcade"
  local TOOL_DIR="$KARNEL_DATA/games/arcade"
  log_info "Uninstalling Terminal Arcade..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "Terminal Arcade uninstalled"
  return 0
}

update_arcade() {
  local TOOL_DIR="$KARNEL_DATA/games/arcade"
  local BIN_NAME="arcade"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Games/Terminal%20Arcade.py"
  log_info "Updating Terminal Arcade..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "Terminal Arcade updated"
  return 0
}

reinstall_arcade() {
  uninstall_arcade
  install_arcade
}
