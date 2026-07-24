#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

upgrade_main() {
  separator
  box "Karnel Upgrade"
  separator
  echo

  import "@/cli/commands/update"
  update_karnel

  source "$KARNEL_PATH/utils/env.sh" 2>/dev/null
  log_success "Karnel upgraded to v$KARNEL_VERSION"

  _upgrade_fix_symlink

  echo
  log_info "Running cleanup..."
  import "@/cli/commands/cleanup"
  cleanup_main
  echo
  log_success "Karnel is up to date (v$KARNEL_VERSION)"
  echo
}

_upgrade_fix_symlink() {
  if [[ ! -L "$PREFIX/bin/karnel" ]] || [[ "$(readlink "$PREFIX/bin/karnel")" != "$KARNEL_PATH/bin/karnel" ]]; then
    ln -sf "$KARNEL_PATH/bin/karnel" "$PREFIX/bin/karnel" 2>/dev/null
    log_success "Symlink updated"
  fi
}
