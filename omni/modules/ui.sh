#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

TERMUX_DIR="$HOME/.termux"
TERMUX_ASSETS_DIR="$(dirname "$OMNI_PATH")/assets"
LOG_FILE="$OMNI_CACHE/install_ui.log"

setup_ui() {
	separator
	box "Configuring Termux UI"
	separator
	echo

	mkdir -p "$(dirname "$LOG_FILE")"

	if [[ ! -d "$TERMUX_DIR" ]]; then
		mkdir -p "$TERMUX_DIR"
		log_info "Created Termux directory: $TERMUX_DIR"
	fi

	local rc=0
	_setup_ui_wrapper || rc=$?
	separator
	if [ "$rc" -eq 0 ]; then
		log_success "Termux UI configuration completed"
	else
		log_warn "$rc UI component(s) failed to configure"
	fi
	separator
	echo
	list_item "Cursor: Green (#00FF00)"
	list_item "Extra-keys: Custom layout with navigation"
	list_item "Font: Meslo Nerd Font"
	list_item "Banner: Omni startup banner"
	echo
	log_warn "Please restart Termux to apply all changes"
	echo
}

_setup_ui_wrapper() {
	import "@/tools/ui/all"
	install_all_ui_components
	return $?
}

uninstall_ui() {
	if [[ ! -d "$TERMUX_DIR" ]]; then
		log_info "Termux UI Configuration is not installed"
		return 0
	fi
	separator
	box "Uninstalling Termux UI Configuration"
	separator
	echo

	mkdir -p "$(dirname "$LOG_FILE")"

	local rc=0
	_uninstall_ui_wrapper || rc=$?
	echo
	separator
	if [ "$rc" -eq 0 ]; then
		log_success "Termux UI configuration uninstalled"
	else
		log_warn "$rc UI component(s) failed to uninstall"
	fi
	separator
	echo
	log_warn "Please restart Termux to apply changes"
	echo
}

_uninstall_ui_wrapper() {
	import "@/tools/ui/all"
	uninstall_all_ui_components
	return $?
}

update_ui() {
	separator
	box "Updating Termux UI Configuration"
	separator
	echo

	mkdir -p "$(dirname "$LOG_FILE")"

	local rc=0
	_update_ui_wrapper || rc=$?
	echo
	separator
	if [ "$rc" -eq 0 ]; then
		log_success "Termux UI configuration updated"
	else
		log_warn "$rc UI component(s) failed to update"
	fi
	separator
	echo
}

_update_ui_wrapper() {
  import "@/tools/ui/all"
  update_all_ui_components
  return $?
}

reinstall_ui() {
  separator
  box "Reinstalling Termux UI Configuration"
  separator
  echo

  mkdir -p "$(dirname "$LOG_FILE")"

  local rc=0
  _reinstall_ui_wrapper || rc=$?
  separator
  if [ "$rc" -eq 0 ]; then
		log_success "Termux UI configuration reinstalled"
  else
		log_warn "$rc UI component(s) failed to reinstall"
  fi
  separator
  echo
  list_item "Cursor: Green (#00FF00)"
  list_item "Extra-keys: Custom layout with navigation"
  list_item "Font: Meslo Nerd Font"
  list_item "Banner: Omni startup banner"
  echo
  log_warn "Please restart Termux to apply all changes"
  echo
}

_reinstall_ui_wrapper() {
  import "@/tools/ui/all"
  reinstall_all_ui_components
  return $?
}