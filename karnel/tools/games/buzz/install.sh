#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_buzz() {
  local TOOL_DIR="$KARNEL_PATH/tools/games/buzz"
  local BIN_NAME="buzz"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Games/Buzz.py"
  if command -v buzz &>/dev/null; then
    log_info "Buzz is already installed"
    return 2
  fi
  log_info "Installing Buzz..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "Buzz installed"
  return 0
}

uninstall_buzz() {
  local BIN_NAME="buzz"
  local TOOL_DIR="$KARNEL_PATH/tools/games/buzz"
  if ! command -v buzz &>/dev/null; then log_info "Buzz is not installed"; return 2; fi
  log_info "Uninstalling Buzz..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "Buzz uninstalled"
  return 0
}

update_buzz() {
  local TOOL_DIR="$KARNEL_PATH/tools/games/buzz"
  local BIN_NAME="buzz"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Games/Buzz.py"
  log_info "Updating Buzz..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "Buzz updated"
  return 0
}

reinstall_buzz() {
  uninstall_buzz
  install_buzz
}
