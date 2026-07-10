#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_lang.log"

install_lang() {
	separator
	box "Installing Language Packages"
	separator
	echo

	log_info "Installing language packages..."

	mkdir -p "$(dirname "$LOG_FILE")"

	local rc=0
	_install_lang_wrapper || rc=$?
	if [ "$rc" -eq 0 ]; then
		log_success "Language packages installed successfully"
	else
		log_warn "$rc language package(s) failed to install"
	fi
	separator
	echo
	list_item "Node.js LTS"
	list_item "Python"
	list_item "Perl"
	list_item "PHP"
	list_item "Rust"
	list_item "C/C++ (clang)"
	list_item "Go (golang)"
	echo
}

_install_lang_wrapper() {
	import "@/tools/lang/all"
	install_all_lang_packages
	return $?
}

uninstall_lang() {
	if ! command -v node &>/dev/null; then
		log_info "Language Packages are not installed"
		return 0
	fi
	separator
	box "Uninstalling Language Packages"
	separator
	echo

	log_info "Uninstalling language packages..."

	local rc=0
	_uninstall_lang_wrapper || rc=$?
	if [ "$rc" -eq 0 ]; then
		log_success "Language packages uninstalled"
	else
		log_warn "$rc language package(s) failed to uninstall"
	fi
}

_uninstall_lang_wrapper() {
	import "@/tools/lang/all"
	uninstall_all_lang_packages
	return $?
}

update_lang() {
	separator
	box "Updating Language Packages"
	separator
	echo

	log_info "Updating language packages..."

	local rc=0
	_update_lang_wrapper || rc=$?
	if [ "$rc" -eq 0 ]; then
		log_success "Language packages updated"
	else
		log_warn "$rc language package(s) failed to update"
	fi
}

_update_lang_wrapper() {
  import "@/tools/lang/all"
  update_all_lang_packages
  return $?
}

reinstall_lang() {
  separator
  box "Reinstalling Language Packages"
  separator
  echo

  log_info "Reinstalling language packages..."

  local rc=0
  _reinstall_lang_wrapper || rc=$?
  if [ "$rc" -eq 0 ]; then
		log_success "Language packages reinstalled successfully"
  else
		log_warn "$rc language package(s) failed to reinstall"
  fi
  separator
  echo
  list_item "Node.js LTS"
  list_item "Python"
  list_item "Perl"
  list_item "PHP"
  list_item "Rust"
  list_item "C/C++ (clang)"
  list_item "Go (golang)"
  echo
}

_reinstall_lang_wrapper() {
  import "@/tools/lang/all"
  reinstall_all_lang_packages
  return $?
}