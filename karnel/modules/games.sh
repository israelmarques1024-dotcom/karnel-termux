#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_games.log"

install_games() {
  separator; box "Installing Games"; separator; echo
  log_info "Installing games..."
  mkdir -p "$(dirname "$LOG_FILE")"
  local rc=0
  import "@/tools/games/all"
  install_all_games || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Games installed" || log_warn "$rc game(s) failed to install"
  return "$rc"
}

uninstall_games() {
  separator; box "Uninstalling Games"; separator; echo
  log_info "Uninstalling games..."
  local rc=0
  import "@/tools/games/all"
  uninstall_all_games || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Games uninstalled" || log_warn "$rc game(s) failed to uninstall"
  return "$rc"
}

update_games() {
  separator; box "Updating Games"; separator; echo
  log_info "Updating games..."
  local rc=0
  import "@/tools/games/all"
  update_all_games || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Games updated" || log_warn "$rc game(s) failed to update"
  return "$rc"
}

reinstall_games() {
  separator; box "Reinstalling Games"; separator; echo
  log_info "Reinstalling games..."
  mkdir -p "$(dirname "$LOG_FILE")"
  local rc=0
  import "@/tools/games/all"
  reinstall_all_games || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Games reinstalled" || log_warn "$rc game(s) failed to reinstall"
  return "$rc"
}
