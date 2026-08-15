#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/tools"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"

OSINT_TOOLS=(
  "robin"
)

for _tool in "${OSINT_TOOLS[@]}"; do
  # shellcheck disable=SC1090
  source "$(dirname "${BASH_SOURCE[0]}")/$_tool/install.sh"
done
unset _tool
_register_safe_reinstall_handlers osint "${OSINT_TOOLS[@]}"

_batch_osint() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local skipped=0
  local total=${#OSINT_TOOLS[@]}
  local current=0
  local rc

  progress_start "$total" "${action_past}ing OSINT tools..."

  for tool in "${OSINT_TOOLS[@]}"; do
    loading "${action_past^}ing ${tool}" _run_tool_lifecycle_action osint "$action" "$tool"
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
  (( skipped > 0 )) && log_info "$skipped OSINT tool(s) already in the requested state"
  (( failed == 0 ))
}

install_all_osint() {
  _batch_osint "install" "install" "installed_count"
}

uninstall_all_osint() {
  _batch_osint "uninstall" "uninstall" "uninstalled_count"
}

update_all_osint() {
  _batch_osint "update" "update" "updated_count"
}

reinstall_all_osint() {
  _batch_osint "reinstall" "reinstall" "reinstalled_count"
}
