#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/downloaded-python"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_pet_friends() {
  local TOOL_DIR="$KARNEL_DATA/games/pet-friends"
  local BIN_NAME="pet-friends"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Games/Pet%20Friends.py"
  log_info "Installing Pet Friends..."
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  _downloaded_python_install "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return $?
  log_success "Pet Friends installed"
  return 0
}

uninstall_pet_friends() {
  local BIN_NAME="pet-friends"
  local TOOL_DIR="$KARNEL_DATA/games/pet-friends"
  log_info "Uninstalling Pet Friends..."
  _downloaded_python_uninstall "$BIN_NAME" "$TOOL_DIR" || return $?
  log_success "Pet Friends uninstalled"
  return 0
}

update_pet_friends() {
  local TOOL_DIR="$KARNEL_DATA/games/pet-friends"
  local BIN_NAME="pet-friends"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/87d69293f4b89b8ab114fa644074629e86313182/Scripts/Games/Pet%20Friends.py"
  log_info "Updating Pet Friends..."
  _downloaded_python_update "$BIN_NAME" "$TOOL_DIR" "$DOWNLOAD_URL" || return 1
  log_success "Pet Friends updated"
  return 0
}

reinstall_pet_friends() {
  uninstall_pet_friends
  install_pet_friends
}
