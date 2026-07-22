#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_detective() {
  local TOOL_DIR="$KARNEL_PATH/tools/games/detective"
  local BIN_NAME="detective"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Games/Detective.py"
  if command -v detective &>/dev/null; then
    log_info "Detective is already installed"
    return 2
  fi
  log_info "Installing Detective..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "Detective installed"
  return 0
}

uninstall_detective() {
  local BIN_NAME="detective"
  local TOOL_DIR="$KARNEL_PATH/tools/games/detective"
  if ! command -v detective &>/dev/null; then log_info "Detective is not installed"; return 2; fi
  log_info "Uninstalling Detective..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "Detective uninstalled"
  return 0
}

update_detective() {
  local TOOL_DIR="$KARNEL_PATH/tools/games/detective"
  local BIN_NAME="detective"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Games/Detective.py"
  log_info "Updating Detective..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "Detective updated"
  return 0
}

reinstall_detective() {
  uninstall_detective
  install_detective
}
