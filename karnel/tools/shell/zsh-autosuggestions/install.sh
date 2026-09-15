#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_shell.log"
ZSH_PLUGINS_DIR="$HOME/.zsh-plugins"
ZSH_AUTOSUGGESTIONS_COMMIT="85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5"
ZSH_AUTOSUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions.git"

_zsh_autosuggestions_dependencies() {
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

_install_zsh_autosuggestions_git() {
  loading "Installing zsh-autosuggestions" _install_zsh_autosuggestions_git_impl
}

_install_zsh_autosuggestions_git_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! install_pinned_git_repo "$ZSH_AUTOSUGGESTIONS_REPO" "$ZSH_AUTOSUGGESTIONS_COMMIT" "$ZSH_PLUGINS_DIR/zsh-autosuggestions"; then
    log_error "Failed to install zsh-autosuggestions"
    return 1
  fi
  return 0
}

install_zsh_autosuggestions() {
  if [[ -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]]; then
    log_info "zsh-autosuggestions already installed"
    return 0
  fi

  _zsh_autosuggestions_dependencies || return 1

  _install_zsh_autosuggestions_git || return 1
  log_success "Installed"
  return 0
}

_uninstall_zsh_autosuggestions_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]]; then
    log_info "zsh-autosuggestions is not installed"
    return 0
  fi

  local remove_rc=0
  confirm_remove_paths "zsh-autosuggestions" "$ZSH_PLUGINS_DIR/zsh-autosuggestions" || remove_rc=$?
  if [[ "$remove_rc" -eq 2 ]]; then
    log_info "zsh-autosuggestions configuration and data preserved"
    return 0
  fi
  return "$remove_rc"
}

uninstall_zsh_autosuggestions() {
  _uninstall_zsh_autosuggestions_impl
}

_update_zsh_autosuggestions_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions/.git" ]]; then
    log_warn "zsh-autosuggestions not installed"
    return 0
  fi

  install_pinned_git_repo "$ZSH_AUTOSUGGESTIONS_REPO" "$ZSH_AUTOSUGGESTIONS_COMMIT" "$ZSH_PLUGINS_DIR/zsh-autosuggestions"
}

update_zsh_autosuggestions() {
  _update_zsh_autosuggestions_impl
}

reinstall_zsh_autosuggestions() {
  uninstall_zsh_autosuggestions
  install_zsh_autosuggestions
}
