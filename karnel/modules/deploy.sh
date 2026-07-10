#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_deploy.log"

install_deploy() {
  separator
  box "Installing Deploy CLIs"
  separator

  log_info "Installing deploy tools (Vercel, Railway, Netlify)..."
  mkdir -p "$(dirname "$LOG_FILE")"
  local rc=0
  _install_deploy_wrapper || rc=$?
  separator
  if [ "$rc" -eq 0 ]; then
    log_success "Deploy tools installed"
  else
    log_warn "$rc deploy tool(s) failed to install"
  fi
}

_install_deploy_wrapper() {
  import "@/tools/deploy/all"
  install_all_deploy_tools
  return $?
}

uninstall_deploy() {
  separator
  box "Uninstalling Deploy CLIs"
  separator
  local rc=0
  import "@/tools/deploy/all"
  uninstall_all_deploy_tools || rc=$?
  separator
  if [ "$rc" -eq 0 ]; then
    log_success "Deploy tools uninstalled"
  else
    log_warn "$rc deploy tool(s) failed to uninstall"
  fi
}

update_deploy() {
  separator
  box "Updating Deploy CLIs"
  separator
  local rc=0
  import "@/tools/deploy/all"
  update_all_deploy_tools || rc=$?
  separator
  if [ "$rc" -eq 0 ]; then
    log_success "Deploy tools updated"
  else
    log_warn "$rc deploy tool(s) failed to update"
  fi
}

reinstall_deploy() {
  separator
  box "Reinstalling Deploy CLIs"
  separator
  local rc=0
  import "@/tools/deploy/all"
  reinstall_all_deploy_tools || rc=$?
  separator
  if [ "$rc" -eq 0 ]; then
    log_success "Deploy tools reinstalled"
  else
    log_warn "$rc deploy tool(s) failed to reinstall"
  fi
}
