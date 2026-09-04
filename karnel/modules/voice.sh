#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_voice.log"
VOICE_MARKER="${KARNEL_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data}/voice/.termux-api-managed"

install_voice() {
  separator
  box "Installing Voice Support"
  separator
  echo

  log_info "Installing Termux:API and dependencies for voice capture..."

  mkdir -p "$(dirname "$LOG_FILE")"

  local deps_rc=0
  loading "Installing Termux:API" _install_voice_deps || deps_rc=$?
  if [ "$deps_rc" -ne 0 ]; then
    log_error "Failed to install Termux:API dependencies"
    return 1
  fi
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
  list_item "Voice CLI: ${D_CYAN}karnel voice [agent]${NC}"
  list_item "Install Termux:API app from: ${D_CYAN}https://karneltermux.vercel.app/termux/api${NC}"
  echo
  return "$rc"
}

_install_voice_deps() {
  if ! pkg install termux-api -y &>>"$LOG_FILE"; then
    return 1
  fi
  mkdir -p "$(dirname "$VOICE_MARKER")" && : >"$VOICE_MARKER"
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
  return "$rc"
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
  return "$rc"
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
  list_item "Voice CLI: ${D_CYAN}karnel voice [agent]${NC}"
  echo
  return "$rc"
}

_reinstall_voice_wrapper() {
  _uninstall_voice_wrapper || return $?
  _install_voice_deps || return $?
  _install_voice_shell
}
