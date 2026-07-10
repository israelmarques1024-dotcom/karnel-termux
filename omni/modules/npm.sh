#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$OMNI_CACHE/install_npm.log"

install_npm() {
	separator
	box "Installing Node.js Modules"
	separator
	echo

	log_info "Installing Node.js global modules..."

	mkdir -p "$(dirname "$LOG_FILE")"

	local install_rc=0
	_install_npm_wrapper || install_rc=$?

	echo
	list_item "TypeScript"
	list_item "NestJS CLI"
	list_item "Prettier"
	list_item "Live Server"
	list_item "Localtunnel"
	list_item "Vercel CLI"
	list_item "Markserv"
	list_item "PSQL Format"
	list_item "NPM Check Updates"
	list_item "Ngrok"
	echo
	separator
	if [ "$install_rc" -eq 0 ]; then
		log_success "Node.js modules installation completed"
	else
		log_warn "$install_rc Node.js module(s) failed to install"
	fi
	separator
	echo
}

_install_npm_wrapper() {
	import "@/tools/npm/all"
	install_all_npm_packages
	return $?
}

uninstall_npm() {
	if ! command -v tsc &>/dev/null; then
		log_info "Node.js Modules are not installed"
		return 0
	fi
	separator
	box "Uninstalling Node.js Modules"
	separator
	echo

	log_info "Uninstalling Node.js global modules..."

	local rc=0
	_uninstall_npm_wrapper || rc=$?

	echo
	separator
	if [ "$rc" -eq 0 ]; then
		log_success "Node.js modules uninstallation completed"
	else
		log_warn "$rc Node.js module(s) failed to uninstall"
	fi
	separator
	echo
}

_uninstall_npm_wrapper() {
	import "@/tools/npm/all"
	uninstall_all_npm_packages
	return $?
}

update_npm() {
	separator
	box "Updating Node.js Modules"
	separator
	echo

	log_info "Updating Node.js global modules..."

	local rc=0
	_update_npm_wrapper || rc=$?

	echo
	separator
	if [ "$rc" -eq 0 ]; then
		log_success "Node.js modules update completed"
	else
		log_warn "$rc Node.js module(s) failed to update"
	fi
	separator
	echo
}

_update_npm_wrapper() {
  import "@/tools/npm/all"
  update_all_npm_packages
  return $?
}

reinstall_npm() {
  separator
  box "Reinstalling Node.js Modules"
  separator
  echo

  log_info "Reinstalling Node.js global modules..."

  local rc=0
  _reinstall_npm_wrapper || rc=$?

  echo
  list_item "TypeScript"
  list_item "NestJS CLI"
  list_item "Prettier"
  list_item "Live Server"
  list_item "Localtunnel"
  list_item "Vercel CLI"
  list_item "Markserv"
  list_item "PSQL Format"
  list_item "NPM Check Updates"
  list_item "Ngrok"
  echo
  separator
  if [ "$rc" -eq 0 ]; then
		log_success "Node.js modules reinstallation completed"
  else
		log_warn "$rc Node.js module(s) failed to reinstall"
  fi
  separator
  echo
}

_reinstall_npm_wrapper() {
  import "@/tools/npm/all"
  reinstall_all_npm_packages
  return $?
}