#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_ctfgod() {
  local TOOL_DIR="$KARNEL_PATH/tools/games/ctfgod"
  local BIN_NAME="ctfgod"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Games/CTF%20God.py"
  if command -v ctfgod &>/dev/null; then
    log_info "CTF God is already installed"
    return 2
  fi
  log_info "Installing CTF God..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "CTF God installed"
  return 0
}

uninstall_ctfgod() {
  local BIN_NAME="ctfgod"
  local TOOL_DIR="$KARNEL_PATH/tools/games/ctfgod"
  if ! command -v ctfgod &>/dev/null; then log_info "CTF God is not installed"; return 2; fi
  log_info "Uninstalling CTF God..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "CTF God uninstalled"
  return 0
}

update_ctfgod() {
  local TOOL_DIR="$KARNEL_PATH/tools/games/ctfgod"
  local BIN_NAME="ctfgod"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Games/CTF%20God.py"
  log_info "Updating CTF God..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "CTF God updated"
  return 0
}

reinstall_ctfgod() {
  uninstall_ctfgod
  install_ctfgod
}
