#!/usr/bin/env bash

import "@/utils/log"

_uninstall_voice_tool() {
  local karnel_data="${KARNEL_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data}"
  local marker="$karnel_data/voice/.termux-api-managed"
  if command -v termux-api &>/dev/null; then
    if [[ -f "$marker" ]]; then
      log_info "Removing Termux:API (installed by Karnel)..."
      if ! pkg uninstall -y termux-api &>>"$LOG_FILE"; then
        log_error "Failed to remove Termux:API (see $LOG_FILE)"
        return 1
      fi
      rm -f "$marker"
      log_success "Termux:API removed"
    else
      log_info "Termux:API is present but was not installed by Karnel; leaving it in place"
    fi
  else
    log_info "Termux:API is not installed"
    rm -f "$marker"
  fi
  return 0
}
