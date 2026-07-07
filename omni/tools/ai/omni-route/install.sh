#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

_install_omni_route_impl() {
  mkdir -p "$PREFIX/bin"
  cat > "$PREFIX/bin/omniroute" <<'EOS'
#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
omniRoute - Free AI Gateway (via npm)

This installs the official omniroute npm package.
See: https://omniroute.online

Usage:
  omniroute          Start gateway on localhost:20128
  omniroute --help   Show omniroute help

Note: Requires Node.js and npm.
USAGE
}

# Check if npm package is installed
if ! command -v npm &>/dev/null; then
  echo "Node.js not installed. Install with: pkg install nodejs" >&2
  exit 1
fi

# Run omniroute via npx (works even if not globally installed)
npx omniroute "$@"
EOS
  chmod +x "$PREFIX/bin/omniroute"
  log_success "omniRoute wrapper installed (runs via npx)"
}

install_omni_route() {
  if command -v omniroute &>/dev/null && omniroute --version &>/dev/null; then
    log_info "omniRoute already installed"
    return 2
  fi
  log_info "Installing omniRoute wrapper..."
  _install_omni_route_impl
}

uninstall_omni_route() {
  rm -f "$PREFIX/bin/omniroute"
  log_success "omniRoute wrapper uninstalled"
  log_info "To remove npm package: npm uninstall -g omniroute"
}

update_omni_route() {
  log_info "omniRoute updates via npm: npm install -g omniroute@latest"
}

reinstall_omni_route() {
  uninstall_omni_route
  install_omni_route
}