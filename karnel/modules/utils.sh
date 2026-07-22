#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_utils.log"

install_utils() {
  separator
  box "Installing Utility Tools"
  separator
  echo

  log_info "Installing utility tools..."

  mkdir -p "$(dirname "$LOG_FILE")"

  local rc=0
  import "@/tools/utils/all"
  install_all_utils || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "Utility tools installed"
  else
    log_warn "$rc utility tool(s) failed to install"
  fi
  separator
  echo
}

uninstall_utils() {
  if ! command -v fconv &>/dev/null && ! command -v notes &>/dev/null; then
    log_info "Utility Tools are not installed"
    return 0
  fi
  separator
  box "Uninstalling Utility Tools"
  separator
  echo

  log_info "Uninstalling utility tools..."

  local rc=0
  import "@/tools/utils/all"
  uninstall_all_utils || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "Utility tools uninstalled"
  else
    log_warn "$rc utility tool(s) failed to uninstall"
  fi
}

update_utils() {
  separator
  box "Updating Utility Tools"
  separator
  echo

  log_info "Updating utility tools..."

  local rc=0
  import "@/tools/utils/all"
  update_all_utils || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "Utility tools updated"
  else
    log_warn "$rc utility tool(s) failed to update"
  fi
}

reinstall_utils() {
  separator
  box "Reinstalling Utility Tools"
  separator
  echo

  log_info "Reinstalling utility tools..."

  local rc=0
  import "@/tools/utils/all"
  reinstall_all_utils || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "Utility tools reinstalled"
  else
    log_warn "$rc utility tool(s) failed to reinstall"
  fi
  separator
  echo
}
