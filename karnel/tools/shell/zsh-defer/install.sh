#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_shell.log"
ZSH_PLUGINS_DIR="$HOME/.zsh-plugins"
ZSH_DEFER_COMMIT="53a26e287fbbe2dcebb3aa1801546c6de32416fa"
ZSH_DEFER_REPO="https://github.com/romkatv/zsh-defer.git"

_zsh_defer_dependencies() {
  declare -A DEPS=(
    ["zsh"]="zsh"
    ["zoxide"]="zoxide"
    ["git"]="git"
  )

  local pkg_name bin_name
  for pkg_name in "${!DEPS[@]}"; do
    bin_name="${DEPS[$pkg_name]}"
    if ! command -v "$bin_name" &>/dev/null; then
      if ! pkg install "$pkg_name" -y &>>"$LOG_FILE"; then
        log_error "Failed to install $pkg_name"
        return 1
      fi
    fi
  done

  log_success "Shell dependencies installed"
  return 0
}

_install_zsh_defer_git() {
  loading "Installing zsh-defer" _install_zsh_defer_git_impl
}

_install_zsh_defer_git_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! install_pinned_git_repo "$ZSH_DEFER_REPO" "$ZSH_DEFER_COMMIT" "$ZSH_PLUGINS_DIR/zsh-defer"; then
    log_error "Failed to install zsh-defer"
    return 1
  fi
  return 0
}

install_zsh_defer() {
  if [[ -d "$ZSH_PLUGINS_DIR/zsh-defer" ]]; then
    log_info "zsh-defer already installed"
    return 0
  fi

  _zsh_defer_dependencies || return 1

  _install_zsh_defer_git || return 1
  log_success "Installed"
  return 0
}

_uninstall_zsh_defer_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-defer" ]]; then
    log_info "zsh-defer is not installed"
    return 2
  fi

  local remove_rc=0
  confirm_remove_paths "zsh-defer" "$ZSH_PLUGINS_DIR/zsh-defer" || remove_rc=$?
  if [[ "$remove_rc" -eq 2 ]]; then
    log_info "zsh-defer configuration and data preserved"
    return 0
  fi
  return "$remove_rc"
}

uninstall_zsh_defer() {
  _uninstall_zsh_defer_impl
}

_update_zsh_defer_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-defer/.git" ]]; then
    log_warn "zsh-defer not installed"
    return 0
  fi

  install_pinned_git_repo "$ZSH_DEFER_REPO" "$ZSH_DEFER_COMMIT" "$ZSH_PLUGINS_DIR/zsh-defer"
}

update_zsh_defer() {
  _update_zsh_defer_impl
}

reinstall_zsh_defer() {
  uninstall_zsh_defer
  install_zsh_defer
}
