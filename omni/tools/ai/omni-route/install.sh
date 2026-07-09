#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

# Check if omni-route binary exists and works
_omni_route_ok() {
  command -v omni-route &>/dev/null && omni-route --version &>/dev/null 2>&1
}

install_omni_route() {
  # Already working? Skip everything
  if _omni_route_ok; then
    log_info "omniRoute already installed ($(omni-route --version 2>&1 | tail -1))"
    return 2
  fi

  # Try local install first (fast, no download)
  local local_bin="$HOME/.omni/packages/omniroute/node_modules/omniroute/bin/omniroute.mjs"
  if [ -f "$local_bin" ]; then
    sed -i '1s|^#!/usr/bin/env node|#!/data/data/com.termux/files/usr/bin/node|' "$local_bin" 2>/dev/null
    # Create both omniroute (official) and omni-route (omni wrapper)
    for cmd in omniroute omni-route; do
      cat > "$PREFIX/bin/$cmd" <<'WRAPPER'
#!/data/data/com.termux/files/usr/bin/env bash
exec node "$HOME/.omni/packages/omniroute/node_modules/omniroute/bin/omniroute.mjs" "$@"
WRAPPER
      chmod +x "$PREFIX/bin/$cmd"
    done
    if _omni_route_ok; then
      log_success "omniRoute restored from local install"
      return 0
    fi
  fi

  # Try npm global install (heavy, ~500MB)
  log_info "Installing omniRoute via npm (this may take a while)..."
  if command -v npm &>/dev/null && npm i -g omniroute 2>>"$LOG_FILE"; then
    if _omni_route_ok; then
      log_success "omniRoute installed via npm"
      return 0
    fi
  fi

  # Try npx as last resort
  log_warn "npm failed, trying npx..."
  if npx -y omniroute --version &>/dev/null 2>&1; then
    log_success "omniRoute available via npx"
    return 0
  fi

  log_error "Failed to install omniRoute"
  return 1
}

uninstall_omni_route() {
  if ! _omni_route_ok; then
    log_info "omniRoute is not installed"
    return 0
  fi

  log_info "Uninstalling omniRoute..."
  npm uninstall -g omniroute 2>>"$LOG_FILE" 2>/dev/null
  rm -f "$PREFIX/bin/omniroute" "$PREFIX/bin/omni-route"
  log_success "omniRoute uninstalled"
  return 0
}

update_omni_route() {
  if ! _omni_route_ok; then
    install_omni_route
    return $?
  fi

  log_info "Updating omniRoute..."
  if npm i -g omniroute@latest 2>>"$LOG_FILE"; then
    log_success "omniRoute updated"
    return 0
  else
    log_error "Failed to update omniRoute"
    return 1
  fi
}

reinstall_omni_route() {
  uninstall_omni_route
  install_omni_route
}
