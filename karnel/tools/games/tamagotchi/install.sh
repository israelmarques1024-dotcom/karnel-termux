#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_tamagotchi() {
  local TOOL_DIR="$KARNEL_PATH/tools/games/tamagotchi"
  local BIN_NAME="tamagotchi"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Games/Tamagotchi.py"
  if command -v tamagotchi &>/dev/null; then
    log_info "Tamagotchi is already installed"
    return 2
  fi
  log_info "Installing Tamagotchi..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "Tamagotchi installed"
  return 0
}

uninstall_tamagotchi() {
  local BIN_NAME="tamagotchi"
  local TOOL_DIR="$KARNEL_PATH/tools/games/tamagotchi"
  if ! command -v tamagotchi &>/dev/null; then log_info "Tamagotchi is not installed"; return 2; fi
  log_info "Uninstalling Tamagotchi..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "Tamagotchi uninstalled"
  return 0
}

update_tamagotchi() {
  local TOOL_DIR="$KARNEL_PATH/tools/games/tamagotchi"
  local BIN_NAME="tamagotchi"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Games/Tamagotchi.py"
  log_info "Updating Tamagotchi..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "Tamagotchi updated"
  return 0
}

reinstall_tamagotchi() {
  uninstall_tamagotchi
  install_tamagotchi
}
