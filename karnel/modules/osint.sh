#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/tools/osint/robin/common"

LOG_FILE="$KARNEL_CACHE/install_osint.log"

install_osint() {
	_robin_print_disclaimer
	separator
  box "Installing OSINT Tools"
  separator
  echo

  log_info "Installing OSINT tools..."
  echo
  mkdir -p "$(dirname "$LOG_FILE")"

  local rc=0
  _install_osint_wrapper || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "OSINT tools installed successfully"
  else
    log_warn "$rc OSINT tool(s) failed to install"
  fi
  separator
  echo
	list_item "Robin — AI-powered Dark Web OSINT tool (Tor + LLM)"
	echo
	return "$rc"
}

_install_osint_wrapper() {
  import "@/tools/osint/all"
  install_all_osint
  return $?
}

uninstall_osint() {
	_robin_print_disclaimer
  if [[ ! -d "$KARNEL_TOOLS/osint" ]]; then
    log_info "OSINT tools are not installed"
    return 0
  fi
  separator
  box "Uninstalling OSINT Tools"
  separator
  echo

  log_info "Uninstalling OSINT tools..."

  local rc=0
  _uninstall_osint_wrapper || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "OSINT tools uninstalled"
  else
    log_warn "$rc OSINT tool(s) failed to uninstall"
  fi
  return "$rc"
}

_uninstall_osint_wrapper() {
  import "@/tools/osint/all"
  uninstall_all_osint
  return $?
}

update_osint() {
	_robin_print_disclaimer
  separator
  box "Updating OSINT Tools"
  separator
  echo

  log_info "Updating OSINT tools..."

  local rc=0
  _update_osint_wrapper || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "OSINT tools updated"
  else
    log_warn "$rc OSINT tool(s) failed to update"
  fi
  return "$rc"
}

_update_osint_wrapper() {
  import "@/tools/osint/all"
  update_all_osint
  return $?
}

reinstall_osint() {
	_robin_print_disclaimer
  separator
  box "Reinstalling OSINT Tools"
  separator
  echo

  log_info "Reinstalling OSINT tools..."
  echo
  mkdir -p "$(dirname "$LOG_FILE")"

  local rc=0
  _reinstall_osint_wrapper || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "OSINT tools reinstalled successfully"
  else
    log_warn "$rc OSINT tool(s) failed to reinstall"
  fi
  separator
  echo
  list_item "Robin — AI-powered Dark Web OSINT tool (Tor + LLM)"
  echo
  return "$rc"
}

_reinstall_osint_wrapper() {
  import "@/tools/osint/all"
  reinstall_all_osint
  return $?
}
