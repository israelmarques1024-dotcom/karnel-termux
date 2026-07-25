#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
GROK_INSTALL_URL="https://x.ai/cli/install.sh"
GROK_DISTRO="ubuntu"
GROK_WRAPPER_DIR="$PREFIX/bin"

_grok_proot() {
  proot-distro login --shared-tmp "$GROK_DISTRO" -- "$@"
}

_grok_ensure_dependencies() {
  mkdir -p "$(dirname "$LOG_FILE")"

  if ! command -v proot-distro &>/dev/null; then
    log_info "Installing proot-distro for Grok CLI compatibility..."
    yes | pkg install proot-distro &>>"$LOG_FILE" || {
      log_error "Failed to install proot-distro"
      return 1
    }
  fi

  if ! proot-distro login "$GROK_DISTRO" -- true &>/dev/null; then
    log_info "Installing Ubuntu container for Grok CLI..."
    proot-distro install "$GROK_DISTRO" &>>"$LOG_FILE" || {
      log_error "Failed to install Ubuntu container"
      return 1
    }
  fi

  _grok_proot /bin/bash -lc \
    'apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates bash' \
    &>>"$LOG_FILE" || {
      log_error "Failed to install Grok CLI dependencies inside Ubuntu"
      return 1
    }
}

_grok_write_wrapper() {
  local name="$1"
  local target="$GROK_WRAPPER_DIR/$name"

  cat >"$target" <<EOF
#!/data/data/com.termux/files/usr/bin/env bash
exec proot-distro login --shared-tmp "$GROK_DISTRO" -- /root/.grok/bin/$name "\$@"
EOF

  chmod +x "$target"
}

_install_grok_cli_impl() {
  _grok_ensure_dependencies || return 1

  log_info "Installing the official Grok CLI inside Ubuntu compatibility layer..."
  _grok_proot /bin/bash -lc \
    "curl -fsSL '$GROK_INSTALL_URL' | bash" \
    &>>"$LOG_FILE" || {
      log_error "Official Grok CLI installer failed"
      return 1
    }

  if ! _grok_proot /bin/bash -lc '/root/.grok/bin/grok --version' &>>"$LOG_FILE"; then
    log_error "Grok CLI was installed but failed its execution check"
    return 1
  fi

  _grok_write_wrapper grok
  _grok_write_wrapper agent

  log_success "Grok CLI installed through Ubuntu compatibility layer"
  log_info "Run 'grok login' to authenticate"
}

install_grok_cli() {
  if command -v grok &>/dev/null; then
    log_info "Grok CLI is already installed"
    return 2
  fi

  loading "Installing Grok CLI" _install_grok_cli_impl
}

_uninstall_grok_cli_impl() {
  rm -f "$GROK_WRAPPER_DIR/grok" "$GROK_WRAPPER_DIR/agent"

  if command -v proot-distro &>/dev/null && proot-distro login "$GROK_DISTRO" -- true &>/dev/null; then
    _grok_proot /bin/bash -lc 'rm -rf /root/.grok' &>>"$LOG_FILE" || {
      log_error "Failed to remove Grok CLI data from Ubuntu"
      return 1
    }
  fi

  log_success "Grok CLI uninstalled"
}

uninstall_grok_cli() {
  if ! command -v grok &>/dev/null; then
    log_info "Grok CLI is not installed"
    return 2
  fi

  loading "Uninstalling Grok CLI" _uninstall_grok_cli_impl
}

_update_grok_cli_impl() {
  _grok_ensure_dependencies || return 1
  _grok_proot /bin/bash -lc \
    "curl -fsSL '$GROK_INSTALL_URL' | bash" \
    &>>"$LOG_FILE" || {
      log_error "Failed to update Grok CLI"
      return 1
    }

  _grok_write_wrapper grok
  _grok_write_wrapper agent
  log_success "Grok CLI updated"
}

update_grok_cli() {
  if ! command -v grok &>/dev/null; then
    install_grok_cli
    return $?
  fi

  loading "Updating Grok CLI" _update_grok_cli_impl
}

reinstall_grok_cli() {
  uninstall_grok_cli || true
  install_grok_cli
}
