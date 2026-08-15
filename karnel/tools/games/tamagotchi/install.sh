#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_tamagotchi() {
  local TOOL_DIR="$KARNEL_DATA/games/tamagotchi"
  local BIN_NAME="tamagotchi"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Games/Tamagotchi.py"
  log_info "Installing Tamagotchi..."
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "Tamagotchi installed"
  return 0
}

uninstall_tamagotchi() {
  local BIN_NAME="tamagotchi"
  local TOOL_DIR="$KARNEL_DATA/games/tamagotchi"
  log_info "Uninstalling Tamagotchi..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "Tamagotchi uninstalled"
  return 0
}

update_tamagotchi() {
  local TOOL_DIR="$KARNEL_DATA/games/tamagotchi"
  local BIN_NAME="tamagotchi"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Games/Tamagotchi.py"
  log_info "Updating Tamagotchi..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "Tamagotchi updated"
  return 0
}

reinstall_tamagotchi() {
  uninstall_tamagotchi
  install_tamagotchi
}
