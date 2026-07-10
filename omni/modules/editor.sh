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

	local rc=0
	_install_editor_wrapper || rc=$?
	if [ "$rc" -eq 0 ]; then
		log_success "Code editor installed successfully"
	else
		log_warn "$rc editor component(s) failed to install"
	fi
	separator
	echo
	list_item "code-server (VS Code in browser)"
	list_item "Access at http://localhost:8080"
	list_item "Set password: ${D_CYAN}code-server --auth password${NC}"
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

	local rc=0
	_uninstall_editor_wrapper || rc=$?
	if [ "$rc" -eq 0 ]; then
		log_success "Code editor uninstalled"
	else
		log_warn "$rc editor component(s) failed to uninstall"
	fi
}

update_editor() {
	separator
	box "Updating Code Editor"
	separator
	echo

	log_info "Updating code-server..."

	local rc=0
	_update_editor_wrapper || rc=$?
	if [ "$rc" -eq 0 ]; then
		log_success "Code editor updated"
	else
		log_warn "$rc editor component(s) failed to update"
	fi
}

reinstall_editor() {
  separator
  box "Reinstalling Code Editor"
  separator
  echo

  log_info "Reinstalling code-server..."

  local rc=0
  _reinstall_editor_wrapper || rc=$?
  if [ "$rc" -eq 0 ]; then
		log_success "Code editor reinstalled successfully"
  else
		log_warn "$rc editor component(s) failed to reinstall"
  fi
  separator
  echo
  list_item "code-server (VS Code in browser)"
  list_item "Access at http://localhost:8080"
  echo
}

_install_editor_wrapper() {
	import "@/tools/editor/all"
	install_all_editor_components
	return $?
}

_uninstall_editor_wrapper() {
	import "@/tools/editor/all"
	uninstall_all_editor_components
	return $?
}

_update_editor_wrapper() {
  import "@/tools/editor/all"
  update_all_editor_components
  return $?
}

_reinstall_editor_wrapper() {
  import "@/tools/editor/all"
  reinstall_all_editor_components
  return $?
}
