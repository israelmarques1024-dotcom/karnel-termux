#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_ctfgod() {
  local TOOL_DIR="$KARNEL_DATA/games/ctfgod"
  local BIN_NAME="ctfgod"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Games/CTF%20God.py"
  log_info "Installing CTF God..."
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "CTF God installed"
  return 0
}

uninstall_ctfgod() {
  local BIN_NAME="ctfgod"
  local TOOL_DIR="$KARNEL_DATA/games/ctfgod"
  log_info "Uninstalling CTF God..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "CTF God uninstalled"
  return 0
}

update_ctfgod() {
  local TOOL_DIR="$KARNEL_DATA/games/ctfgod"
  local BIN_NAME="ctfgod"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Games/CTF%20God.py"
  log_info "Updating CTF God..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "CTF God updated"
  return 0
}

reinstall_ctfgod() {
  uninstall_ctfgod
  install_ctfgod
}
