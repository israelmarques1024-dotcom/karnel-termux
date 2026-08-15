#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_shell.log"
ZSH_PLUGINS_DIR="$HOME/.zsh-plugins"
YOU_SHOULD_USE_COMMIT="5f3d129864ee4505043d88c3486224f1d75b692e"
YOU_SHOULD_USE_REPO="https://github.com/MichaelAquilina/zsh-you-should-use.git"

_you_should_use_dependencies() {
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

_install_you_should_use_git() {
  loading "Installing zsh-you-should-use" _install_you_should_use_git_impl
}

_install_you_should_use_git_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! install_pinned_git_repo "$YOU_SHOULD_USE_REPO" "$YOU_SHOULD_USE_COMMIT" "$ZSH_PLUGINS_DIR/zsh-you-should-use"; then
    log_error "Failed to install zsh-you-should-use"
    return 1
  fi
  return 0
}

install_you_should_use() {
  if [[ -d "$ZSH_PLUGINS_DIR/zsh-you-should-use" ]]; then
    log_info "zsh-you-should-use already installed"
    return 0
  fi

  _you_should_use_dependencies || return 1

  _install_you_should_use_git || return 1
  log_success "Installed"
  return 0
}

_uninstall_you_should_use_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-you-should-use" ]]; then
    log_info "zsh-you-should-use is not installed"
    return 0
  fi

  local remove_rc=0
  confirm_remove_paths "zsh-you-should-use" "$ZSH_PLUGINS_DIR/zsh-you-should-use" || remove_rc=$?
  if [[ "$remove_rc" -eq 2 ]]; then
    log_info "zsh-you-should-use configuration and data preserved"
    return 0
  fi
  return "$remove_rc"
}

uninstall_you_should_use() {
  _uninstall_you_should_use_impl
}

_update_you_should_use_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-you-should-use/.git" ]]; then
    log_warn "zsh-you-should-use not installed"
    return 0
  fi

  install_pinned_git_repo "$YOU_SHOULD_USE_REPO" "$YOU_SHOULD_USE_COMMIT" "$ZSH_PLUGINS_DIR/zsh-you-should-use"
}

update_you_should_use() {
  _update_you_should_use_impl
}

reinstall_you_should_use() {
  uninstall_you_should_use
  install_you_should_use
}
