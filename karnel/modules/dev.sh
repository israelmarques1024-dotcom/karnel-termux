#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

install_dev() {
	separator
	box "Installing Development Tools"
	separator
	echo

	log_info "Installing development tools..."

	mkdir -p "$(dirname "$LOG_FILE")"

	local rc=0
	_install_dev_wrapper || rc=$?
	if [ "$rc" -eq 0 ]; then
		log_success "Tools installed successfully"
	else
		log_warn "$rc tool(s) failed to install"
	fi
	separator
	echo
	list_item "GitHub CLI"
	list_item "Wget"
	list_item "Curl"
	list_item "LSD (ls replacement)"
	list_item "Bat (cat replacement)"
	list_item "Proot (chroot alternative)"
	list_item "Ncurses Utils"
	list_item "Tmate (terminal sharing)"
	list_item "OpenSSH"
	list_item "Tmux"
	list_item "Cloudflared (Cloudflare Tunnel)"
	list_item "Translate Shell"
	list_item "html2text (HTML to text converter)"
	list_item "jq (JSON processor)"
	list_item "bc (calculator)"
	list_item "Tree (directory listing)"
	list_item "Fzf (fuzzy finder)"
	list_item "ImageMagick (image manipulation)"
	list_item "Shfmt (shell script formatter)"
	list_item "Make (build automation)"
	list_item "Udocker (container management)"
	list_item "Snyk (security scanner)"
	list_item "httptmux (interactive API client)"
	list_item "Zork (text adventure games I, II, III)"
	list_item "Fconv (file converter)"
	list_item "Filecheck (file integrity)"
	list_item "Websites (project scaffold)"
	list_item "Notes (terminal notes)"
	list_item "Treex (tree explorer)"
	list_item "Passman (password manager)"
	list_item "Applaunch (app launcher)"
	list_item "Splash (startup splash)"
	echo
}

_install_dev_wrapper() {
	import "@/tools/dev/all"
	install_all_dev
	return $?
}

uninstall_dev() {
	if ! command -v gh &>/dev/null; then
		log_info "Development Tools are not installed"
		return 0
	fi
	separator
	box "Uninstalling Development Tools"
	separator
	echo

	log_info "Uninstalling development tools..."

	local rc=0
	_uninstall_dev_wrapper || rc=$?
	if [ "$rc" -eq 0 ]; then
		log_success "Tools uninstalled"
	else
		log_warn "$rc tool(s) failed to uninstall"
	fi
}

_uninstall_dev_wrapper() {
	import "@/tools/dev/all"
	uninstall_all_dev
	return $?
}

update_dev() {
	separator
	box "Updating Development Tools"
	separator
	echo

	log_info "Updating development tools..."

	local rc=0
	_update_dev_wrapper || rc=$?
	if [ "$rc" -eq 0 ]; then
		log_success "Tools updated"
	else
		log_warn "$rc tool(s) failed to update"
	fi
}

_update_dev_wrapper() {
  import "@/tools/dev/all"
  update_all_dev
  return $?
}

reinstall_dev() {
  separator
  box "Reinstalling Development Tools"
  separator
  echo

  log_info "Reinstalling development tools..."

  local rc=0
  _reinstall_dev_wrapper || rc=$?
  if [ "$rc" -eq 0 ]; then
		log_success "Tools reinstalled successfully"
  else
		log_warn "$rc tool(s) failed to reinstall"
  fi
  separator
  echo
  list_item "GitHub CLI"
  list_item "Wget"
  list_item "Curl"
  list_item "LSD (ls replacement)"
  list_item "Bat (cat replacement)"
  list_item "Proot (chroot alternative)"
  list_item "Ncurses Utils"
  list_item "Tmate (terminal sharing)"
  list_item "OpenSSH"
  list_item "Tmux"
  list_item "Cloudflared (Cloudflare Tunnel)"
  list_item "Translate Shell"
  list_item "html2text (HTML to text converter)"
  list_item "jq (JSON processor)"
  list_item "bc (calculator)"
  list_item "Tree (directory listing)"
  list_item "Fzf (fuzzy finder)"
  list_item "ImageMagick (image manipulation)"
  list_item "Shfmt (shell script formatter)"
	list_item "Make (build automation)"
	list_item "Udocker (container management)"
	list_item "Snyk (security scanner)"
	list_item "httptmux (interactive API client)"
	list_item "Zork (text adventure games I, II, III)"
	list_item "Fconv (file converter)"
	list_item "Filecheck (file integrity)"
	list_item "Websites (project scaffold)"
	list_item "Notes (terminal notes)"
	list_item "Treex (tree explorer)"
	list_item "Passman (password manager)"
	list_item "Applaunch (app launcher)"
	list_item "Splash (startup splash)"
	echo
}

_reinstall_dev_wrapper() {
  import "@/tools/dev/all"
  reinstall_all_dev
  return $?
}