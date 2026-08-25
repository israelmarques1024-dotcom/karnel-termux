#!/usr/bin/env bash

import "@/utils/log"

_uninstall_voice_tool() {
  if command -v termux-api &>/dev/null; then
    log_info "Removing Termux:API..."
    if ! pkg uninstall -y termux-api &>>"$LOG_FILE"; then
      log_error "Failed to remove Termux:API (see $LOG_FILE)"
      return 1
    fi
    log_success "Termux:API removed"
  else
    log_info "Termux:API is not installed"
  fi
  return 0
}
