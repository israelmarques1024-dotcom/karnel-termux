#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$OMNI_CACHE/install_editor.log"

install_editor() {
	separator
	box "Installing Code Editor"
	separator
	echo

	log_info "Installing code-server (VS Code in browser)..."

	mkdir -p "$(dirname "$LOG_FILE")"

	_install_editor_wrapper
	log_success "Code editor installed successfully"
	separator
	echo
	list_item "code-server (VS Code in browser)"
	list_item "Access at http://localhost:8080"
	list_item "Password: 12092013iI@"
	echo
}

uninstall_editor() {
	if ! command -v code-server &>/dev/null; then
		log_info "Code Editor is not installed"
		return 0
	fi
	separator
	box "Uninstalling Code Editor"
	separator
	echo

	log_info "Uninstalling code-server..."

	_uninstall_editor_wrapper
	log_success "Code editor uninstalled"
}

update_editor() {
	separator
	box "Updating Code Editor"
	separator
	echo

	log_info "Updating code-server..."

	_update_editor_wrapper
	log_success "Code editor updated"
}

reinstall_editor() {
  separator
  box "Reinstalling Code Editor"
  separator
  echo

  log_info "Reinstalling code-server..."

  _reinstall_editor_wrapper
  log_success "Code editor reinstalled successfully"
  separator
  echo
  list_item "code-server (VS Code in browser)"
  list_item "Access at http://localhost:8080"
  echo
}

_install_editor_wrapper() {
	import "@/tools/editor/all"
	install_all_editor_components
}

_uninstall_editor_wrapper() {
	import "@/tools/editor/all"
	uninstall_all_editor_components
}

_update_editor_wrapper() {
  import "@/tools/editor/all"
  update_all_editor_components
}

_reinstall_editor_wrapper() {
  import "@/tools/editor/all"
  reinstall_all_editor_components
}
