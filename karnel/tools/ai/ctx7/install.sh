#!/usr/bin/env bash

# ctx7 (Context7) - Real-time documentation provider for AI coding assistants
# Provides version-specific library docs and code examples on-demand
# Solves stale knowledge issues in AI tools like Claude Code, Cursor
# Official: npm install -g ctx7
import "@/utils/log"
import "@/utils/version"

install_ctx7() {
  if command -v ctx7 &>/dev/null; then
    log_info "ctx7 is already installed"
    return 2
  fi

  log_info "Installing ctx7 (Context7 documentation provider)..."
  npm install -g ctx7 2>/dev/null
  local rc=$?

  local _t
  _t=$(readlink -f "$PREFIX/bin/ctx7" 2>/dev/null)
  [ -f "$_t" ] && sed -i '1s|^#!/usr/bin/env node|#!/data/data/com.termux/files/usr/bin/env node|' "$_t"

  if [[ $rc -eq 0 ]] && command -v ctx7 &>/dev/null; then
    log_success "ctx7 installed successfully"
    log_info "Use as MCP server: ctx7 --help"
    return 0
  else
    log_error "ctx7 installation failed"
    return 1
  fi
}

uninstall_ctx7() {
  if ! command -v ctx7 &>/dev/null; then
    log_info "ctx7 is not installed"
    return 0
  fi

  log_info "Uninstalling ctx7..."
  npm uninstall -g ctx7 2>/dev/null
  return $?
}

update_ctx7() {
  _check_update_needed "ctx7" "$(_get_installed_npm_version ctx7)" "$(_get_remote_npm_version ctx7)" _do_update_ctx7
}

_do_update_ctx7() {
  npm update -g ctx7 2>/dev/null
  local _t
  _t=$(readlink -f "$PREFIX/bin/ctx7" 2>/dev/null)
  [ -f "$_t" ] && sed -i '1s|^#!/usr/bin/env node|#!/data/data/com.termux/files/usr/bin/env node|' "$_t"
  return $?
}

reinstall_ctx7() {
  uninstall_ctx7 2>/dev/null
  install_ctx7
  return $?
}
