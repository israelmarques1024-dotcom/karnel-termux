#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$OMNI_CACHE/install_voice.log"

install_voice() {
  separator
  box "Installing Voice Support"
  separator
  echo

  log_info "Installing Termux:API and dependencies for voice capture..."

  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Installing Termux:API" _install_voice_deps
  log_success "Voice dependencies installed"

  _install_voice_shell
  log_success "Voice support installed successfully"
  separator
  echo
  list_item "Termux:API (speech-to-text, clipboard)"
  list_item "Termux:API app (Android APK)"
  list_item "Voice CLI: ${D_CYAN}omni voice [agent]${NC}"
  list_item "Install Termux:API app from: ${D_CYAN}https://omni-catalyst.vercel.app/termux/api${NC}"
  echo
}

_install_voice_deps() {
  pkg install termux-api -y &>"$LOG_FILE"
}

_install_voice_shell() {
  import "@/tools/voice/all"
  install_all_voice_components
}

uninstall_voice() {
  separator
  box "Uninstalling Voice Support"
  separator
  echo

  log_info "Removing voice components..."

  _uninstall_voice_wrapper
  log_success "Voice support uninstalled"
}

_uninstall_voice_wrapper() {
  import "@/tools/voice/all"
  uninstall_all_voice_components
}

update_voice() {
  separator
  box "Updating Voice Support"
  separator
  echo

  log_info "Updating voice configuration..."
  _update_voice_wrapper
  log_success "Voice support updated"
}

_update_voice_wrapper() {
  import "@/tools/voice/all"
  update_all_voice_components
}

reinstall_voice() {
  separator
  box "Reinstalling Voice Support"
  separator
  echo

  log_info "Reinstalling voice dependencies..."

  _reinstall_voice_wrapper
  log_success "Voice support reinstalled successfully"
  separator
  echo
  list_item "Termux:API (speech-to-text, clipboard)"
  list_item "Voice CLI: ${D_CYAN}omni voice [agent]${NC}"
  echo
}

_reinstall_voice_wrapper() {
  import "@/tools/voice/all"
  reinstall_all_voice_components
}
