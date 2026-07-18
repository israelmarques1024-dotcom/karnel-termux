#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

start_main() {
  if [[ $# -eq 0 ]]; then
    echo
    box "Karnel Start"
    echo
    log_info "Usage: karnel start <target>"
    echo
    list_item "editor    - Start code-server (VS Code in browser)"
    list_item "robin     - Start Tor + Robin on 127.0.0.1:8501"
    echo
    return
  fi

  local target="$1"
  shift

  case "$target" in
  editor)
    _start_editor "$@"
    ;;
  robin)
    import "@/cli/commands/robin"
    robin_main start "$@"
    ;;
  *)
    log_warn "Unknown start target: $target"
    log_info "Run 'karnel start' to see available targets"
    ;;
  esac
}

_start_editor() {
  if ! command -v code-server &>/dev/null; then
    log_warn "code-server is not installed"
    log_info "Install with: ${D_CYAN}karnel install editor${NC}"
    return 1
  fi

  local port="${1:-8080}"

  echo
  box "Starting code-server"
  echo
  log_info "Starting VS Code in browser..."
  log_info "Port: $port"
  log_info "Password set via --auth password flag"
  echo
  log_success "Open http://localhost:$port in your browser"
  echo
  log_info "Press Ctrl+C to stop"
  echo

  code-server . --bind-addr "0.0.0.0:$port" --auth password
}
