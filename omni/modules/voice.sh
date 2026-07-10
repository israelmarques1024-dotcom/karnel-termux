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

  local rc=0
  _install_voice_shell || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "Voice support installed successfully"
  else
    log_warn "$rc voice component(s) failed to install"
  fi
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
  return $?
}

uninstall_voice() {
  separator
  box "Uninstalling Voice Support"
  separator
  echo

  log_info "Removing voice components..."

  local rc=0
  _uninstall_voice_wrapper || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "Voice support uninstalled"
  else
    log_warn "$rc voice component(s) failed to uninstall"
  fi
}

_uninstall_voice_wrapper() {
  import "@/tools/voice/all"
  uninstall_all_voice_components
  return $?
}

update_voice() {
  separator
  box "Updating Voice Support"
  separator
  echo

  log_info "Updating voice configuration..."
  local rc=0
  _update_voice_wrapper || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "Voice support updated"
  else
    log_warn "$rc voice component(s) failed to update"
  fi
}

_update_voice_wrapper() {
  import "@/tools/voice/all"
  update_all_voice_components
  return $?
}

reinstall_voice() {
  separator
  box "Reinstalling Voice Support"
  separator
  echo

  log_info "Reinstalling voice dependencies..."

  local rc=0
  _reinstall_voice_wrapper || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "Voice support reinstalled successfully"
  else
    log_warn "$rc voice component(s) failed to reinstall"
  fi
  separator
  echo
  list_item "Termux:API (speech-to-text, clipboard)"
  list_item "Voice CLI: ${D_CYAN}omni voice [agent]${NC}"
  echo
}

_reinstall_voice_wrapper() {
  import "@/tools/voice/all"
  reinstall_all_voice_components
  return $?
}
