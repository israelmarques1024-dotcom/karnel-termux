#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_games() {
  separator
  box "Installing Games"
  separator
  echo

  log_info "Installing games..."

  mkdir -p "$(dirname "$LOG_FILE")"

  local rc=0
  import "@/tools/games/all"
  install_all_games || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "Games installed"
  else
    log_warn "$rc game(s) failed to install"
  fi
  separator
  echo
}

uninstall_games() {
  if ! command -v buzz &>/dev/null && ! command -v ctfgod &>/dev/null; then
    log_info "Games are not installed"
    return 0
  fi
  separator
  box "Uninstalling Games"
  separator
  echo

  log_info "Uninstalling games..."

  local rc=0
  import "@/tools/games/all"
  uninstall_all_games || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "Games uninstalled"
  else
    log_warn "$rc game(s) failed to uninstall"
  fi
}

update_games() {
  separator
  box "Updating Games"
  separator
  echo

  log_info "Updating games..."

  local rc=0
  import "@/tools/games/all"
  update_all_games || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "Games updated"
  else
    log_warn "$rc game(s) failed to update"
  fi
}

reinstall_games() {
  separator
  box "Reinstalling Games"
  separator
  echo

  log_info "Reinstalling games..."

  local rc=0
  import "@/tools/games/all"
  reinstall_all_games || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "Games reinstalled"
  else
    log_warn "$rc game(s) failed to reinstall"
  fi
  separator
  echo
}
