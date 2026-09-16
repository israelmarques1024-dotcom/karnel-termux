#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_utils.log"

install_utils() {
  separator; box "Installing Utility Tools"; separator; echo
  log_info "Installing utility tools..."
  local rc=0
  import "@/tools/utils/all"
  install_all_utils || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Utility tools installed" || log_warn "$rc utility tool(s) failed to install"
  return "$rc"
}

uninstall_utils() {
  separator; box "Uninstalling Utility Tools"; separator; echo
  log_info "Uninstalling utility tools..."
  local rc=0
  import "@/tools/utils/all"
  uninstall_all_utils || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Utility tools uninstalled" || log_warn "$rc utility tool(s) failed to uninstall"
  return "$rc"
}

update_utils() {
  separator; box "Updating Utility Tools"; separator; echo
  log_info "Updating utility tools..."
  local rc=0
  import "@/tools/utils/all"
  update_all_utils || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Utility tools updated" || log_warn "$rc utility tool(s) failed to update"
  return "$rc"
}

reinstall_utils() {
  separator; box "Reinstalling Utility Tools"; separator; echo
  log_info "Reinstalling utility tools..."
  local rc=0
  import "@/tools/utils/all"
  reinstall_all_utils || rc=$?
  separator
  [[ "$rc" -eq 0 ]] && log_success "Utility tools reinstalled" || log_warn "$rc utility tool(s) failed to reinstall"
  return "$rc"
}
