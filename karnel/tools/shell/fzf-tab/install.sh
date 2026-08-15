#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_shell.log"
ZSH_PLUGINS_DIR="$HOME/.zsh-plugins"
FZF_TAB_COMMIT="24105b15714bfec37989ed5c5b6e60f572253019"
FZF_TAB_REPO="https://github.com/Aloxaf/fzf-tab.git"

_fzf_tab_dependencies() {
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

_install_fzf_tab_git() {
  loading "Installing fzf-tab" _install_fzf_tab_git_impl
}

_install_fzf_tab_git_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! install_pinned_git_repo "$FZF_TAB_REPO" "$FZF_TAB_COMMIT" "$ZSH_PLUGINS_DIR/fzf-tab"; then
    log_error "Failed to install fzf-tab"
    return 1
  fi
  return 0
}

install_fzf_tab() {
  if [[ -d "$ZSH_PLUGINS_DIR/fzf-tab" ]]; then
    log_info "fzf-tab already installed"
    return 0
  fi

  _fzf_tab_dependencies || return 1

  _install_fzf_tab_git || return 1
  log_success "Installed"
  return 0
}

_uninstall_fzf_tab_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/fzf-tab" ]]; then
    log_info "fzf-tab is not installed"
    return 0
  fi

  local remove_rc=0
  confirm_remove_paths "fzf-tab" "$ZSH_PLUGINS_DIR/fzf-tab" || remove_rc=$?
  if [[ "$remove_rc" -eq 2 ]]; then
    log_info "fzf-tab configuration and data preserved"
    return 0
  fi
  return "$remove_rc"
}

uninstall_fzf_tab() {
  _uninstall_fzf_tab_impl
}

_update_fzf_tab_impl() {
  if [[ ! -d "$ZSH_PLUGINS_DIR/fzf-tab/.git" ]]; then
    log_warn "fzf-tab not installed"
    return 0
  fi

  install_pinned_git_repo "$FZF_TAB_REPO" "$FZF_TAB_COMMIT" "$ZSH_PLUGINS_DIR/fzf-tab"
}

update_fzf_tab() {
  _update_fzf_tab_impl
}

reinstall_fzf_tab() {
  uninstall_fzf_tab
  install_fzf_tab
}
