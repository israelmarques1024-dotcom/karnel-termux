#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$KARNEL_CACHE/install_voice.log"

install_all_voice_components() {
  log_info "Installing voice shell components..."
  import "@/tools/voice/install"
  _install_voice_tool
}

uninstall_all_voice_components() {
  log_info "Removing voice shell components..."
  import "@/tools/voice/uninstall"
  _uninstall_voice_tool
}

update_all_voice_components() {
  log_info "Voice components are managed by Termux:API — no update needed"
  return 0
}

reinstall_all_voice_components() {
  uninstall_all_voice_components
  install_all_voice_components
}
