#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_websites() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/websites"
  local BIN_NAME="websites"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Developer%20Base/Simple%20Websites%20Creator.py"
  if command -v websites &>/dev/null; then
    log_info "Websites Creator is already installed"
    return 2
  fi
  log_info "Installing Websites Creator..."
  mkdir -p "$(dirname "$LOG_FILE")" "$TOOL_DIR"
  if ! command -v python3 &>/dev/null; then pkg install python -y &>>"$LOG_FILE" || return 1; fi

  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  chmod +x "$TOOL_DIR/$BIN_NAME.py"
  sed -i "1s|.*|#\!$PREFIX/bin/python3|" "$TOOL_DIR/$BIN_NAME.py"
  ln -sf "$TOOL_DIR/$BIN_NAME.py" "$PREFIX/bin/$BIN_NAME"
  log_success "Websites Creator installed"
  return 0
}

uninstall_websites() {
  local BIN_NAME="websites"
  local TOOL_DIR="$KARNEL_PATH/tools/utils/websites"
  if ! command -v websites &>/dev/null; then log_info "Websites Creator is not installed"; return 2; fi
  log_info "Uninstalling Websites Creator..."
  rm -f "$PREFIX/bin/$BIN_NAME" "$TOOL_DIR/$BIN_NAME.py"
  log_success "Websites Creator uninstalled"
  return 0
}

update_websites() {
  local TOOL_DIR="$KARNEL_PATH/tools/utils/websites"
  local BIN_NAME="websites"
  local DOWNLOAD_URL="https://raw.githubusercontent.com/dedsec1121fk/DedSec/main/Scripts/Developer%20Base/Simple%20Websites%20Creator.py"
  log_info "Updating Websites Creator..."
  curl -sL "$DOWNLOAD_URL" -o "$TOOL_DIR/$BIN_NAME.py" || return 1
  log_success "Websites Creator updated"
  return 0
}

reinstall_websites() {
  uninstall_websites
  install_websites
}
