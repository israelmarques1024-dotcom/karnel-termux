#!/usr/bin/env bash

import "@/utils/log"

NETWORK_TOOLS=(
  "dark"
  "dedsec-network"
)

for _tool in "${NETWORK_TOOLS[@]}"; do
  source "$(dirname "${BASH_SOURCE[0]}")/$_tool/install.sh"
done
unset _tool

_batch_network() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local skipped=0
  local total=${#NETWORK_TOOLS[@]}
  local current=0
  local func_name

  progress_start "$total" "${action_past}ing network tools..."

  for tool in "${NETWORK_TOOLS[@]}"; do
    func_name="${action}_${tool//-/_}"
    if declare -f "$func_name" &>/dev/null; then
      loading "${action_past^}ing ${tool}" "$func_name"
      case $? in
        0) ((count++)) ;;
        2) ((skipped++)) ;;
        *) ((failed++)) ;;
      esac
    else
      log_error "Missing network action: $func_name"
      ((failed++))
    fi
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  (( skipped > 0 )) && log_info "$skipped network tool(s) already in the requested state"
  (( failed == 0 ))
}

install_all_network() {
  _batch_network "install" "install" "installed_count"
}

uninstall_all_network() {
  _batch_network "uninstall" "uninstall" "uninstalled_count"
}

update_all_network() {
  _batch_network "update" "update" "updated_count"
}

reinstall_all_network() {
  _batch_network "reinstall" "reinstall" "reinstalled_count"
}
