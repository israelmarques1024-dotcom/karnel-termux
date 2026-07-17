#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_pet_friends() {
  local TOOL_DIR="$KARNEL_PATH/tools/games/pet-friends"
  local BIN_NAME="pet-friends"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Games/Pet%20Friends.py"
  if command -v pet-friends &>/dev/null; then
    log_info "Pet Friends is already installed"
    return 2
  fi
  log_info "Installing Pet Friends..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "Pet Friends installed"
  return 0
}

uninstall_pet_friends() {
  local BIN_NAME="pet-friends"
  local TOOL_DIR="$KARNEL_PATH/tools/games/pet-friends"
  if ! command -v pet-friends &>/dev/null; then log_info "Pet Friends is not installed"; return 2; fi
  log_info "Uninstalling Pet Friends..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "Pet Friends uninstalled"
  return 0
}

update_pet_friends() {
  local TOOL_DIR="$KARNEL_PATH/tools/games/pet-friends"
  local BIN_NAME="pet-friends"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Games/Pet%20Friends.py"
  log_info "Updating Pet Friends..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "Pet Friends updated"
  return 0
}

reinstall_pet_friends() {
  uninstall_pet_friends
  install_pet_friends
}
