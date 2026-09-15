#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_shell.log"
ZSH_PLUGINS_DIR="$HOME/.zsh-plugins"
ZSH_COMPLETIONS_COMMIT="2798b16c74f80cda2094cfed4516db8048d3e6ca"
ZSH_COMPLETIONS_REPO="https://github.com/zsh-users/zsh-completions.git"

_zsh_completions_dependencies() {
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

_install_zsh_completions_git() {
  loading "Installing zsh-completions" _install_zsh_completions_git_impl
}

_install_zsh_completions_git_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! install_pinned_git_repo "$ZSH_COMPLETIONS_REPO" "$ZSH_COMPLETIONS_COMMIT" "$ZSH_PLUGINS_DIR/zsh-completions"; then
    log_error "Failed to install zsh-completions"
    return 1
  fi
  return 0
}

install_zsh_completions() {
  if [[ -d "$ZSH_PLUGINS_DIR/zsh-completions" ]]; then
    log_info "zsh-completions already installed"
    return 0
  fi

  _zsh_completions_dependencies || return 1

  _install_zsh_completions_git || return 1
  log_success "Installed"
  return 0
}

_uninstall_zsh_completions_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-completions" ]]; then
    log_info "zsh-completions is not installed"
    return 0
  fi

  local remove_rc=0
  confirm_remove_paths "zsh-completions" "$ZSH_PLUGINS_DIR/zsh-completions" || remove_rc=$?
  if [[ "$remove_rc" -eq 2 ]]; then
    log_info "zsh-completions configuration and data preserved"
    return 0
  fi
  return "$remove_rc"
}

uninstall_zsh_completions() {
  _uninstall_zsh_completions_impl
}

_update_zsh_completions_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-completions/.git" ]]; then
    log_warn "zsh-completions not installed"
    return 0
  fi

  install_pinned_git_repo "$ZSH_COMPLETIONS_REPO" "$ZSH_COMPLETIONS_COMMIT" "$ZSH_PLUGINS_DIR/zsh-completions"
}

update_zsh_completions() {
  _update_zsh_completions_impl
}

reinstall_zsh_completions() {
  uninstall_zsh_completions
  install_zsh_completions
}
