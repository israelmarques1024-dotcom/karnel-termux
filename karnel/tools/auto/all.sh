#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/tools"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"

LOG_FILE="$KARNEL_CACHE/install_auto.log"

AUTOMATION_TOOLS=(
  "n8n"
)

for _tool in "${AUTOMATION_TOOLS[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool
_register_safe_reinstall_handlers auto "${AUTOMATION_TOOLS[@]}"

_batch_auto() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#AUTOMATION_TOOLS[@]}
  local current=0
  local rc

  progress_start "$total" "${action_past}ing automation tools..."

  for tool in "${AUTOMATION_TOOLS[@]}"; do
    loading "${action_past^}ing ${tool}" _run_tool_lifecycle_action auto "$action" "$tool"
    rc=$?
    case $rc in 0) ((count++));; 2) :;; *) ((failed++));; esac
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  (( failed == 0 ))
}

install_all_auto_tools() {
  _batch_auto "install" "install" "installed_count"
}

uninstall_all_auto_tools() {
  _batch_auto "uninstall" "uninstall" "uninstalled_count"
}

update_all_auto_tools() {
  _batch_auto "update" "update" "updated_count"
}

reinstall_all_auto_tools() {
  _batch_auto "reinstall" "reinstall" "reinstalled_count"
}
