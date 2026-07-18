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
	_show_dev_summary
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
  _show_dev_summary
  echo
}

_reinstall_dev_wrapper() {
  import "@/tools/dev/all"
  reinstall_all_dev
  return $?
}

_show_dev_summary() {
  local idx=0
  for tool in "${TOOLS_PACKAGES[@]}"; do
    local display="${TOOLS_DISPLAY[$idx]:-$tool}"
    local result="${_INSTALL_RESULTS[$tool]:-}"
    case "$result" in
      0) list_item_check success "$display" ;;
      2) list_item_check pending "$display" ;;
      1) list_item_check fail "$display" ;;
      *) list_item "$display" ;;
    esac
    ((idx++))
  done
}
