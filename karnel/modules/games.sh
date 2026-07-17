#!/usr/bin/env bash
import "@/utils/log"

install_games() {
  local installed_count=0
  log_info "Installing games..."
  import "@/tools/games/all"
  install_all_games || return 1
  log_success "Games installed"
  return 0
}
