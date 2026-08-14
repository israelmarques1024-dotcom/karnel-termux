#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_ai.log"

install_ai() {
  separator
  box "Installing AI Tools"
  separator
  echo

  log_info "Installing AI tools..."
  echo
  log_info "☕ Grab a coffee! This process typically takes 1h-2h hours."
  log_info "   Don't worry, it's normal for this to take a while..."
  echo

  mkdir -p "$(dirname "$LOG_FILE")"

  # Captura o exit code do instalador batch
  local install_rc=0
  _install_ai_tools_wrapper || install_rc=$?

  separator

  if [ "$install_rc" -eq 0 ]; then
    log_success "AI tools installed successfully"
  else
    log_warn "AI tools installed with $install_rc failure(s)"
    log_info "Check the details above for which tools failed"
    log_info "Run ${D_CYAN}karnel doctor${NC} for system diagnostics"
  fi

  echo
  log_info "Tools installed and their commands:"
  echo

  # Mostra apenas ferramentas que foram realmente instaladas (command -v)
  local _reg_entry _id _name _bins _bin
  local -a _registered_bins
  for _reg_entry in "${AI_TOOLS_REGISTRY[@]}"; do
    IFS=':' read -r _id _name _bins <<< "$_reg_entry"
    IFS=',' read -ra _registered_bins <<< "$_bins"
    for _bin in "${_registered_bins[@]}"; do
      if command -v "$_bin" &>/dev/null; then
        list_item "$_name ${GRAY}(${D_GREEN}$_bin${GRAY})"
        break
      fi
    done
  done

  echo
  return $install_rc
}

_install_ai_tools_wrapper() {
  import "@/tools/ai/all"
  install_all_ai_tools
}

uninstall_ai() {
  import "@/tools/ai/all"

  separator
  box "Uninstalling AI Tools"
  separator
  echo

  log_info "Uninstalling AI tools..."

  local rc=0
  _uninstall_ai_tools_wrapper || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "AI tools uninstalled"
  else
    log_warn "AI tools uninstalled with $rc failure(s)"
  fi
  return "$rc"
}

_uninstall_ai_tools_wrapper() {
  import "@/tools/ai/all"
  uninstall_all_ai_tools
}

update_ai() {
  separator
  box "Updating AI Tools"
  separator
  echo

  log_info "Updating AI tools..."

  local rc=0
  _update_ai_tools_wrapper || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "AI tools updated"
  else
    log_warn "AI tools updated with $rc failure(s)"
  fi
  return "$rc"
}

_update_ai_tools_wrapper() {
  import "@/tools/ai/all"
  update_all_ai_tools
}

reinstall_ai() {
  separator
  box "Reinstalling AI Tools"
  separator
  echo

  log_info "Reinstalling AI tools..."
  echo

  local rc=0
  import "@/tools/ai/all"
  reinstall_all_ai_tools || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_success "AI tools reinstalled successfully"
  else
    log_warn "AI tools reinstalled with $rc failure(s)"
  fi
  echo
  return "$rc"
}
