#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_shell.log"
ZSH_PLUGINS_DIR="$HOME/.zsh-plugins"
ZSH_SYNTAX_HIGHLIGHTING_COMMIT="c4d95591843d49838b7ad30081e7aba3135a6703"
ZSH_SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"

_zsh_syntax_highlighting_dependencies() {
  if command -v git &>/dev/null && command -v zsh &>/dev/null; then
    return 0
  fi

  mkdir -p "$(dirname "$LOG_FILE")"
  pkg install zsh zoxide git -y &>>"$LOG_FILE"
}

_install_zsh_syntax_highlighting_git() {
  loading "Installing zsh-syntax-highlighting" _install_zsh_syntax_highlighting_git_impl
}

_install_zsh_syntax_highlighting_git_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! install_pinned_git_repo "$ZSH_SYNTAX_HIGHLIGHTING_REPO" "$ZSH_SYNTAX_HIGHLIGHTING_COMMIT" "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting"; then
    log_error "Failed to install zsh-syntax-highlighting"
    return 1
  fi
  return 0
}

install_zsh_syntax_highlighting() {
  if [[ -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
    log_info "zsh-syntax-highlighting already installed"
    return 0
  fi

  _zsh_syntax_highlighting_dependencies || return 1

  _install_zsh_syntax_highlighting_git || return 1
  log_success "Installed"
  return 0
}

_uninstall_zsh_syntax_highlighting_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
    log_info "zsh-syntax-highlighting is not installed"
    return 0
  fi

  local remove_rc=0
  confirm_remove_paths "zsh-syntax-highlighting" "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" || remove_rc=$?
  if [[ "$remove_rc" -eq 2 ]]; then
    log_info "zsh-syntax-highlighting configuration and data preserved"
    return 0
  fi
  return "$remove_rc"
}

uninstall_zsh_syntax_highlighting() {
  _uninstall_zsh_syntax_highlighting_impl
}

_update_zsh_syntax_highlighting_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/.git" ]]; then
    log_warn "zsh-syntax-highlighting not installed"
    return 0
  fi

  install_pinned_git_repo "$ZSH_SYNTAX_HIGHLIGHTING_REPO" "$ZSH_SYNTAX_HIGHLIGHTING_COMMIT" "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting"
}

update_zsh_syntax_highlighting() {
  _update_zsh_syntax_highlighting_impl
}

reinstall_zsh_syntax_highlighting() {
  uninstall_zsh_syntax_highlighting
  install_zsh_syntax_highlighting
}
