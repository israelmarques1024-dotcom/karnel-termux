#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

_install_fzf_pkg() {
	loading "Installing Fzf" _install_fzf_pkg_impl
}

_install_fzf_pkg_impl() {
	if ! pkg install fzf -y &>>"$LOG_FILE"; then
		log_error "Failed to install Fzf"
		return 1
	fi
	return 0
}

_uninstall_fzf_pkg() {
	loading "Uninstalling Fzf" _uninstall_fzf_pkg_impl
}

_uninstall_fzf_pkg_impl() {
	if ! pkg uninstall fzf -y &>>"$LOG_FILE"; then
		log_error "Failed to uninstall Fzf"
		return 1
	fi
	return 0
}

_update_fzf_pkg() {
	loading "Updating Fzf" _update_fzf_pkg_impl
}

_update_fzf_pkg_impl() {
	if ! pkg upgrade fzf -y &>>"$LOG_FILE"; then
		log_error "Failed to update Fzf"
		return 1
	fi
	return 0
}

_fix_fzf_zshrc() {
  local zshrc="$HOME/.zshrc"
  [[ -f "$zshrc" ]] || return 0

  if ! grep -qs "fzf/key-bindings" "$zshrc" 2>/dev/null; then
    return 0
  fi

  if grep -qs "autoload.*up-line-or-beginning-search" "$zshrc" 2>/dev/null; then
    return 0
  fi

  local tmpfile
  tmpfile=$(mktemp)
  while IFS= read -r line; do
    if [[ "$line" == *"fzf/key-bindings"* ]]; then
      echo "# Ensure up-line-or-beginning-search is available for fzf" >> "$tmpfile"
      echo "autoload -Uz up-line-or-beginning-search 2>/dev/null" >> "$tmpfile"
      echo "zle -N up-line-or-beginning-search 2>/dev/null" >> "$tmpfile"
    fi
    echo "$line" >> "$tmpfile"
  done < "$zshrc"
  mv "$tmpfile" "$zshrc"
  log_info "Fixed zsh up-line-or-beginning-search widget loading for fzf"
}

install_fzf() {
  if command -v fzf &>/dev/null; then
    log_info "Fzf is already installed"
    return 2
  fi
  log_info "Installing Fzf..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _install_fzf_pkg || return 1
  _fix_fzf_zshrc
  log_success "Fzf installed"
  return 0
}

uninstall_fzf() {
	if ! command -v fzf &>/dev/null; then
		log_info "Fzf is not installed"
		return 2
	fi
	log_info "Uninstalling Fzf..."
	mkdir -p "$(dirname "$LOG_FILE")"

	_uninstall_fzf_pkg || return 1
	log_success "Fzf uninstalled"
	return 0
}

update_fzf() {
  _check_update_needed "FZF" "$(_get_installed_pkg_version fzf)" "$(_get_remote_pkg_version fzf)" _update_fzf_pkg
}

reinstall_fzf() {
	uninstall_fzf
	install_fzf
}
