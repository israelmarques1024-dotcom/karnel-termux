# Template for security tool installers.
# Copy this file and replace TOOL_NAME with the actual tool name.

_TOOL="tool"
_TOOL_PKG="$1"

install_${_TOOL}() {
  if command -v "$_TOOL" &>/dev/null; then
    log_info "$_TOOL is already installed"
    return 2
  fi
  log_info "Installing $_TOOL..."
  if pkg install -y "$_TOOL_PKG" 2>/dev/null || apt install -y "$_TOOL_PKG" 2>/dev/null; then
    log_success "$_TOOL installed"
    return 0
  fi
  log_error "Failed to install $_TOOL"
  return 1
}

uninstall_${_TOOL}() {
  log_info "Removing $_TOOL..."
  pkg uninstall -y "$_TOOL_PKG" 2>/dev/null || true
  log_success "$_TOOL removed"
}

update_${_TOOL}() {
  log_info "$_TOOL updated via package manager"
  return 2
}

reinstall_${_TOOL}() {
  uninstall_$_TOOL
  install_$_TOOL
}
