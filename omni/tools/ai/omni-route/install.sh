#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

_install_omni_route_impl() {
  mkdir -p "$PREFIX/bin"
  cat > "$PREFIX/bin/omni-route" <<'EOS'
#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
omniRoute - Official AI Gateway

Documentation: https://omniroute.online
GitHub: https://github.com/diegosouzapw/OmniRoute

Usage:
  omniroute          Start gateway on localhost:20128
  omniroute --help   Show omniroute help

Install:
  npm install -g omniroute
USAGE
}

echo "omniRoute - AI Gateway"
echo "Docs: https://omniroute.online"
echo "GitHub: https://github.com/diegosouzapw/OmniRoute"
echo ""
echo "Install with: npm install -g omniroute"
EOS
  chmod +x "$PREFIX/bin/omni-route"
  log_success "omniRoute installed"
}

install_omni_route() {
  if command -v omni-route &>/dev/null; then
    log_info "omniRoute already installed"
    return 2
  fi
  log_info "Installing omniRoute..."
  _install_omni_route_impl
}

uninstall_omni_route() {
  rm -f "$PREFIX/bin/omni-route"
  log_success "omniRoute uninstalled"
}

update_omni_route() {
  log_info "omniRoute updates via npm: npm install -g omniroute@latest"
}

reinstall_omni_route() {
  uninstall_omni_route
  install_omni_route
}