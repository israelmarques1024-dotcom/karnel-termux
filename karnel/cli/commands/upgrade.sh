#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

upgrade_main() {
  echo
  box "Karnel Upgrade"
  echo

  log_info "Upgrading Karnel framework to latest version..."

  # Pull latest from git
  if ! git -C "$KARNEL_PATH/.." pull origin main 2>/dev/null; then
    log_warn "Git pull failed — check your internet connection"
    return 1
  fi

  log_success "Repository updated"

  # Re-source env for new version
  source "$KARNEL_PATH/utils/env.sh" 2>/dev/null
  log_success "Karnel v$KARNEL_VERSION"

  # Verify symlink
  if [[ ! -L "$PREFIX/bin/karnel" ]] || [[ "$(readlink "$PREFIX/bin/karnel")" != "$KARNEL_PATH/bin/karnel" ]]; then
    ln -sf "$KARNEL_PATH/bin/karnel" "$PREFIX/bin/karnel"
    log_success "Symlink updated"
  fi

  # Run cleanup
  echo
  log_info "Running cleanup..."
  import "@/cli/commands/cleanup"
  cleanup_main

  echo
  log_success "Karnel is up to date (v$KARNEL_VERSION)"
  echo
}
