#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$OMNI_CACHE/install_db.log"

install_db() {
	separator
	box "Installing Databases"
	separator
	echo

	log_info "Installing databases..."

	mkdir -p "$(dirname "$LOG_FILE")"

	local install_rc=0
	_install_db_tools_wrapper || install_rc=$?

	separator

	if [ "$install_rc" -eq 0 ]; then
		log_success "Databases installed successfully"
	else
		log_warn "$install_rc database(s) failed to install"
		log_info "Run ${D_CYAN}omni doctor${NC} for diagnostics"
	fi

	separator
	echo
	list_item "PostgreSQL"
	list_item "MariaDB (MySQL)"
	list_item "SQLite"
	list_item "MongoDB"
	echo
}

_install_db_tools_wrapper() {
	import "@/tools/db/all"
	install_all_db_tools
	return $?
}

uninstall_db() {
	if ! command -v postgres &>/dev/null; then
		log_info "Databases are not installed"
		return 0
	fi
	separator
	box "Uninstalling Databases"
	separator
	echo

	log_info "Uninstalling databases..."

	local rc=0
	_uninstall_db_tools_wrapper || rc=$?

	separator

	if [ "$rc" -eq 0 ]; then
		log_success "Databases uninstalled"
	else
		log_warn "$rc database(s) failed to uninstall"
	fi
}

_uninstall_db_tools_wrapper() {
	import "@/tools/db/all"
	uninstall_all_db_tools
	return $?
}

update_db() {
	separator
	box "Updating Databases"
	separator
	echo

	log_info "Updating databases..."

	local rc=0
	_update_db_tools_wrapper || rc=$?

	separator

	if [ "$rc" -eq 0 ]; then
		log_success "Databases updated"
	else
		log_warn "$rc database(s) failed to update"
	fi
}

_update_db_tools_wrapper() {
  import "@/tools/db/all"
  update_all_db_tools
  return $?
}

reinstall_db() {
  separator
  box "Reinstalling Databases"
  separator
  echo

  log_info "Reinstalling databases..."

  local rc=0
  _reinstall_db_tools_wrapper || rc=$?

  separator

  if [ "$rc" -eq 0 ]; then
		log_success "Databases reinstalled successfully"
  else
		log_warn "$rc database(s) failed to reinstall"
  fi

  echo
  list_item "PostgreSQL"
  list_item "MariaDB (MySQL)"
  list_item "SQLite"
  list_item "MongoDB"
  echo
}

_reinstall_db_tools_wrapper() {
  import "@/tools/db/all"
  reinstall_all_db_tools
  return $?
}