#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_detective() {
  local TOOL_DIR="$KARNEL_DATA/games/detective"
  local BIN_NAME="detective"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Games/Detective.py"
  log_info "Installing Detective..."
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "Detective installed"
  return 0
}

uninstall_detective() {
  local BIN_NAME="detective"
  local TOOL_DIR="$KARNEL_DATA/games/detective"
  log_info "Uninstalling Detective..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "Detective uninstalled"
  return 0
}

update_detective() {
  local TOOL_DIR="$KARNEL_DATA/games/detective"
  local BIN_NAME="detective"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Games/Detective.py"
  log_info "Updating Detective..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "Detective updated"
  return 0
}

reinstall_detective() {
  uninstall_detective
  install_detective
}
