#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

upgrade_main() {
  separator
  box "Karnel Upgrade"
  separator
  echo

  local karnel_root
  karnel_root="$(cd "$KARNEL_PATH/.." && pwd 2>/dev/null || echo "")"

  if [[ -d "$karnel_root/.git" ]]; then
    _upgrade_from_git "$karnel_root"
  elif command -v npm &>/dev/null && npm list -g karnel-termux &>/dev/null 2>&1; then
    _upgrade_from_npm
  elif command -v pnpm &>/dev/null && pnpm list -g karnel-termux &>/dev/null 2>&1; then
    _upgrade_from_pnpm
  else
    log_warn "Cannot detect installation method"
    log_info "Reinstall via:"
    list_item "npm:  npm install -g karnel-termux@latest"
    list_item "curl: bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/israelmarques1024-dotcom/karnel-termux/main/install.sh)\""
  fi
}

_upgrade_from_git() {
  local karnel_root="$1"
  log_info "Upgrading from git..."
  if ! git -C "$karnel_root" pull origin main 2>/dev/null; then
    log_warn "Git pull failed — check internet connection"
    return 1
  fi

  log_success "Repository updated"
  source "$KARNEL_PATH/utils/env.sh" 2>/dev/null
  log_success "Karnel v$KARNEL_VERSION"

  if [[ ! -L "$PREFIX/bin/karnel" ]] || [[ "$(readlink "$PREFIX/bin/karnel")" != "$KARNEL_PATH/bin/karnel" ]]; then
    ln -sf "$KARNEL_PATH/bin/karnel" "$PREFIX/bin/karnel"
    log_success "Symlink updated"
  fi

  echo
  log_success "Karnel upgraded! Run 'karnel doctor' to verify."
  echo
}

_upgrade_from_npm() {
  log_info "Upgrading via npm..."
  if npm install -g karnel-termux@latest 2>&1; then
    local new_ver
    new_ver=$(npm list -g karnel-termux 2>/dev/null | grep karnel-termux | grep -oP '@\K[0-9.]+')
    log_success "Karnel upgraded to v$new_ver"
  else
    log_error "npm upgrade failed"
  fi
}

_upgrade_from_pnpm() {
  log_info "Upgrading via pnpm..."
  if pnpm add -g karnel-termux@latest 2>&1; then
    log_success "Karnel upgraded via pnpm"
  else
    log_error "pnpm upgrade failed"
  fi
}
