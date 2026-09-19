#!/usr/bin/env bash
# shellcheck shell=bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_security.log"

install_security() {
  separator
  box "Installing Security Tools"
  separator
  echo
  log_info "Installing security tools..."
  mkdir -p "$(dirname "$LOG_FILE")"
  local rc=0
  import "@/tools/security/all"
  install_all_security || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Security tools installed" || log_warn "$rc security tool(s) failed to install"
  return "$rc"
}

uninstall_security() {
  separator
  box "Uninstalling Security Tools"
  separator
  echo
  log_info "Uninstalling security tools..."
  local rc=0
  import "@/tools/security/all"
  uninstall_all_security || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Security tools uninstalled" || log_warn "$rc security tool(s) failed to uninstall"
  return "$rc"
}

update_security() {
  separator
  box "Updating Security Tools"
  separator
  echo
  log_info "Updating security tools..."
  local rc=0
  import "@/tools/security/all"
  update_all_security || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Security tools updated" || log_warn "$rc security tool(s) failed to update"
  return "$rc"
}

reinstall_security() {
  separator
  box "Reinstalling Security Tools"
  separator
  echo
  log_info "Reinstalling security tools..."
  mkdir -p "$(dirname "$LOG_FILE")"
  local rc=0
  import "@/tools/security/all"
  reinstall_all_security || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Security tools reinstalled" || log_warn "$rc security tool(s) failed to reinstall"
  return "$rc"
}
