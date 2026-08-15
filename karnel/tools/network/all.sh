#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/tools"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"

NETWORK_TOOLS=(
  "dark"
  "dedsec-network"
)

for _tool in "${NETWORK_TOOLS[@]}"; do
  source "$(dirname "${BASH_SOURCE[0]}")/$_tool/install.sh"
done
unset _tool
_register_safe_reinstall_handlers network "${NETWORK_TOOLS[@]}"

_batch_network() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local skipped=0
  local total=${#NETWORK_TOOLS[@]}
  local current=0
  local rc

  progress_start "$total" "${action_past}ing network tools..."

  for tool in "${NETWORK_TOOLS[@]}"; do
    loading "${action_past^}ing ${tool}" _run_tool_lifecycle_action network "$action" "$tool"
    rc=$?
    case $rc in
      0) ((count++)) ;;
      2) ((skipped++)) ;;
      *) ((failed++)) ;;
    esac
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
