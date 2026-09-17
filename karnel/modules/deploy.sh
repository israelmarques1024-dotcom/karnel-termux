#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_deploy.log"

install_deploy() {
  separator; box "Installing Deploy CLIs"; separator; echo
  log_info "Installing deploy tools..."
  mkdir -p "$(dirname "$LOG_FILE")"
  local rc=0
  import "@/tools/deploy/all"
  install_all_deploy_tools || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Deploy tools installed" || log_warn "$rc deploy tool(s) failed to install"
  return "$rc"
}

uninstall_deploy() {
  separator; box "Uninstalling Deploy CLIs"; separator; echo
  log_info "Uninstalling deploy tools..."
  local rc=0
  import "@/tools/deploy/all"
  uninstall_all_deploy_tools || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Deploy tools uninstalled" || log_warn "$rc deploy tool(s) failed to uninstall"
  return "$rc"
}

update_deploy() {
  separator; box "Updating Deploy CLIs"; separator; echo
  log_info "Updating deploy tools..."
  local rc=0
  import "@/tools/deploy/all"
  update_all_deploy_tools || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Deploy tools updated" || log_warn "$rc deploy tool(s) failed to update"
  return "$rc"
}

reinstall_deploy() {
  separator; box "Reinstalling Deploy CLIs"; separator; echo
  log_info "Reinstalling deploy tools..."
  mkdir -p "$(dirname "$LOG_FILE")"
  local rc=0
  import "@/tools/deploy/all"
  reinstall_all_deploy_tools || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Deploy tools reinstalled" || log_warn "$rc deploy tool(s) failed to reinstall"
  return "$rc"
}
