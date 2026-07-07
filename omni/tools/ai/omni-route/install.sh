#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_ai.log"

_install_omni_route_impl() {
  mkdir -p "$PREFIX/bin"
  cat > "$PREFIX/bin/omni-route" <<'EOS'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
omniRoute - AI CLI routes manager

Usage:
  omni-route list          List installed AI CLIs
  omni-route show <cli>    Show CLI path
  omni-route --help        Show this help
USAGE
}

cmd="${1:-}"
shift || true

case "$cmd" in
  list)
    IFS=$'\n'
    for bin in $(command -v opencode claude codex qwen vibe hermes kimi ollama odysseus openclaw freebuff pi agy mmx gentle-ai gga engram codegraph kilow command-code kimchi 2>/dev/null || true); do
      [ -n "$bin" ] && echo "$bin"
    done | sort
    ;;
  show)
    echo "$1"
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    echo "Unknown command: $cmd"
    usage
    return 1
    ;;
esac
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
  log_info "omniRoute updated"
}

reinstall_omni_route() {
  uninstall_omni_route
  install_omni_route
}