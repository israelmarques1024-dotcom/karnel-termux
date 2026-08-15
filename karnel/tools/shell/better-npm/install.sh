#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_shell.log"
ZSH_PLUGINS_DIR="$HOME/.zsh-plugins"
BETTER_NPM_COMMIT="02ca404a9b585b59788b15af53d4f46fac297153"
BETTER_NPM_REPO="https://github.com/lukechilds/zsh-better-npm-completion.git"

_better_npm_dependencies() {
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

_install_better_npm_git() {
  loading "Installing zsh-better-npm-completion" _install_better_npm_git_impl
}

_install_better_npm_git_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! install_pinned_git_repo "$BETTER_NPM_REPO" "$BETTER_NPM_COMMIT" "$ZSH_PLUGINS_DIR/zsh-better-npm-completion"; then
    log_error "Failed to install zsh-better-npm-completion"
    return 1
  fi
  return 0
}

install_better_npm() {
  if [[ -d "$ZSH_PLUGINS_DIR/zsh-better-npm-completion" ]]; then
    log_info "zsh-better-npm-completion already installed"
    return 0
  fi

  _better_npm_dependencies || return 1

  _install_better_npm_git || return 1
  log_success "Installed"
  return 0
}

_uninstall_better_npm_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-better-npm-completion" ]]; then
    log_info "zsh-better-npm-completion is not installed"
    return 0
  fi

  local remove_rc=0
  confirm_remove_paths "zsh-better-npm-completion" "$ZSH_PLUGINS_DIR/zsh-better-npm-completion" || remove_rc=$?
  if [[ "$remove_rc" -eq 2 ]]; then
    log_info "zsh-better-npm-completion configuration and data preserved"
    return 0
  fi
  return "$remove_rc"
}

uninstall_better_npm() {
  _uninstall_better_npm_impl
}

_update_better_npm_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-better-npm-completion/.git" ]]; then
    log_warn "zsh-better-npm-completion not installed"
    return 0
  fi

  install_pinned_git_repo "$BETTER_NPM_REPO" "$BETTER_NPM_COMMIT" "$ZSH_PLUGINS_DIR/zsh-better-npm-completion"
}

update_better_npm() {
  _update_better_npm_impl
}

reinstall_better_npm() {
  uninstall_better_npm
  install_better_npm
}
