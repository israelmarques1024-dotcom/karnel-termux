#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$OMNI_CACHE/install_ai.log"
KIMCHI_PLUGIN="@kimchi-dev/opencode-kimchi"

_kimchi_dependencies() {
  loading "Checking dependencies" _kimchi_dependencies_impl
}

_kimchi_dependencies_impl() {
  if ! command -v opencode &>/dev/null; then
    log_warn "OpenCode is required for Kimchi AI plugin"
    log_info "Installing OpenCode first..."
    import "@/tools/ai/opencode/install"
    install_opencode || {
      log_error "Failed to install OpenCode (required for Kimchi)"
      return 1
    }
  fi
  return 0
}

_install_kimchi_plugin() {
  loading "Installing Kimchi AI plugin" _install_kimchi_plugin_impl
}

_install_kimchi_plugin_impl() {
  local opencode_config="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

  if npm install -g "$KIMCHI_PLUGIN" &>>"$LOG_FILE"; then
    mkdir -p "$opencode_config/node_modules"
    ln -sf "$PREFIX/lib/node_modules/@kimchi-dev" \
      "$opencode_config/node_modules/@kimchi-dev" 2>/dev/null
    return 0
  fi

  log_error "Failed to install Kimchi AI plugin"
  return 1
}

install_kimchi_code() {
  if [ -f "$PREFIX/bin/kimchi" ]; then
    log_info "Kimchi AI is already installed"
    return 2
  fi

  log_info "Installing Kimchi AI (OpenCode plugin for Cast AI)..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _kimchi_dependencies || return 1
  _install_kimchi_plugin || return 1

  local wrapper_path="$PREFIX/bin/kimchi"
  cat > "$wrapper_path" << WRAPPER
#!$PREFIX/bin/bash
if [ \$# -eq 0 ]; then
  echo "Kimchi AI - OpenCode plugin for Cast AI"
  echo "Usage: kimchi <prompt>"
  echo "       kimchi -i                      # Interactive mode"
  echo "Run an AI prompt using Kimchi's Cast AI models via OpenCode."
  exit 0
fi

ARGS=()
INTERACTIVE=false
for arg in "\$@"; do
  if [ "\$arg" = "-i" ] || [ "\$arg" = "--interactive" ]; then
    INTERACTIVE=true
  else
    ARGS+=("\$arg")
  fi
done

if [ "\$INTERACTIVE" = true ]; then
  exec opencode run --interactive "\${ARGS[@]}"
else
  exec opencode run "\${ARGS[@]}"
fi
WRAPPER
  chmod +x "$wrapper_path"

  log_success "Kimchi AI installed (OpenCode plugin)"
  log_info "Usage: ${D_CYAN}kimchi <prompt>${NC}"
  log_info "Configure provider: ${D_CYAN}opencode providers login${NC}"
  return 0
}

uninstall_kimchi_code() {
  log_info "Uninstalling Kimchi AI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  npm uninstall -g "$KIMCHI_PLUGIN" &>>"$LOG_FILE" 2>/dev/null || true
  rm -f "$PREFIX/bin/kimchi" 2>/dev/null
  rm -rf "$HOME/.config/opencode/node_modules/@kimchi-dev" 2>/dev/null

  log_success "Kimchi AI uninstalled"
  return 0
}

update_kimchi_code() {
  log_info "Updating Kimchi AI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  npm update -g "$KIMCHI_PLUGIN" &>>"$LOG_FILE" && {
    log_success "Kimchi AI updated"
    return 0
  }

  log_error "Failed to update Kimchi AI"
  return 1
}

reinstall_kimchi_code() {
  uninstall_kimchi_code
  install_kimchi_code
}
