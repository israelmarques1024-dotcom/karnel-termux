#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_arcade() {
  local TOOL_DIR="$KARNEL_PATH/tools/games/arcade"
  local BIN_NAME="arcade"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Games/Terminal%20Arcade.py"
  if command -v arcade &>/dev/null; then
    log_info "Terminal Arcade is already installed"
    return 2
  fi
  log_info "Installing Terminal Arcade..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "Terminal Arcade installed"
  return 0
}

uninstall_arcade() {
  local BIN_NAME="arcade"
  local TOOL_DIR="$KARNEL_PATH/tools/games/arcade"
  if ! command -v arcade &>/dev/null; then log_info "Terminal Arcade is not installed"; return 2; fi
  log_info "Uninstalling Terminal Arcade..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "Terminal Arcade uninstalled"
  return 0
}

update_arcade() {
  local TOOL_DIR="$KARNEL_PATH/tools/games/arcade"
  local BIN_NAME="arcade"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Games/Terminal%20Arcade.py"
  log_info "Updating Terminal Arcade..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "Terminal Arcade updated"
  return 0
}

reinstall_arcade() {
  uninstall_arcade
  install_arcade
}
