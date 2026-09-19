#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

upgrade_main() {
  separator
  box "Karnel Upgrade"
  separator
  echo

  import "@/cli/commands/update"
  if ! update_karnel; then
    log_error "Karnel upgrade failed"
    return 1
  fi

  if ! _upgrade_fix_symlink; then
    log_error "Karnel upgrade could not activate its command"
    return 1
  fi

  source "$KARNEL_PATH/utils/env.sh" 2>/dev/null
  log_success "Karnel upgraded to v$KARNEL_VERSION"

  echo
  log_info "Running cleanup..."
  import "@/cli/commands/cleanup"
  local cleanup_rc=0
  cleanup_main || cleanup_rc=$?
  if [[ "$cleanup_rc" -ne 0 ]]; then
    log_warn "Cleanup completed with warnings"
  fi
  echo
  log_success "Karnel is up to date (v$KARNEL_VERSION)"
  echo
}

_upgrade_fix_symlink() {
  if [[ -e "$PREFIX/bin/karnel" && ! -L "$PREFIX/bin/karnel" ]]; then
    log_error "Refusing to replace existing non-symlink: $PREFIX/bin/karnel"
    return 1
  fi
  if [[ ! -L "$PREFIX/bin/karnel" ]] || [[ "$(readlink "$PREFIX/bin/karnel")" != "$KARNEL_PATH/bin/karnel" ]]; then
    ln -sf "$KARNEL_PATH/bin/karnel" "$PREFIX/bin/karnel" 2>/dev/null
    log_success "Symlink updated"
  fi
}
