#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_shell.log"
ZSH_PLUGINS_DIR="$HOME/.zsh-plugins"
ZSH_AUTOPAIR_COMMIT="449a7c3d095bc8f3d78cf37b9549f8bb4c383f3d"
ZSH_AUTOPAIR_REPO="https://github.com/hlissner/zsh-autopair.git"

_zsh_autopair_dependencies() {
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

_install_zsh_autopair_git() {
  loading "Installing zsh-autopair" _install_zsh_autopair_git_impl
}

_install_zsh_autopair_git_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! install_pinned_git_repo "$ZSH_AUTOPAIR_REPO" "$ZSH_AUTOPAIR_COMMIT" "$ZSH_PLUGINS_DIR/zsh-autopair"; then
    log_error "Failed to install zsh-autopair"
    return 1
  fi
  return 0
}

install_zsh_autopair() {
  if [[ -d "$ZSH_PLUGINS_DIR/zsh-autopair" ]]; then
    log_info "zsh-autopair already installed"
    return 0
  fi

  _zsh_autopair_dependencies || return 1

  _install_zsh_autopair_git || return 1
  log_success "Installed"
  return 0
}

_uninstall_zsh_autopair_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-autopair" ]]; then
    log_info "zsh-autopair is not installed"
    return 0
  fi

  local remove_rc=0
  confirm_remove_paths "zsh-autopair" "$ZSH_PLUGINS_DIR/zsh-autopair" || remove_rc=$?
  if [[ "$remove_rc" -eq 2 ]]; then
    log_info "zsh-autopair configuration and data preserved"
    return 0
  fi
  return "$remove_rc"
}

uninstall_zsh_autopair() {
  _uninstall_zsh_autopair_impl
}

_update_zsh_autopair_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-autopair/.git" ]]; then
    log_warn "zsh-autopair not installed"
    return 0
  fi

  install_pinned_git_repo "$ZSH_AUTOPAIR_REPO" "$ZSH_AUTOPAIR_COMMIT" "$ZSH_PLUGINS_DIR/zsh-autopair"
}

update_zsh_autopair() {
  _update_zsh_autopair_impl
}

reinstall_zsh_autopair() {
  uninstall_zsh_autopair
  install_zsh_autopair
}
