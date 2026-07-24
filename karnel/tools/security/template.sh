# shellcheck shell=bash

# Template for security tool installers.
# Copy this file, replace `tool` in the function names, and set TOOL_NAME/TOOL_PKG.

TOOL_NAME="tool"
TOOL_PKG="tool"

install_tool() {
  if command -v "$TOOL_NAME" &>/dev/null; then
    log_info "$TOOL_NAME is already installed"
    return 2
  fi
  log_info "Installing $TOOL_NAME..."
  if pkg install -y "$TOOL_PKG" 2>/dev/null || apt install -y "$TOOL_PKG" 2>/dev/null; then
    log_success "$TOOL_NAME installed"
    return 0
  fi
  log_error "Failed to install $TOOL_NAME"
  return 1
}

uninstall_tool() {
  log_info "Removing $TOOL_NAME..."
  if pkg uninstall -y "$TOOL_PKG" 2>/dev/null || apt remove -y "$TOOL_PKG" 2>/dev/null; then
    log_success "$TOOL_NAME removed"
    return 0
  fi
  log_error "Failed to remove $TOOL_NAME"
  return 1
}

update_tool() {
  log_info "$TOOL_NAME is updated via package manager"
  return 2
}

reinstall_tool() {
  uninstall_tool || return 1
  install_tool
}
