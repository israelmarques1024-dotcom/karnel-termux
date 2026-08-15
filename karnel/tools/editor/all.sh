#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/tools"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"

LOG_FILE="$KARNEL_CACHE/install_editor.log"

EDITOR_COMPONENTS=(
  "code-server"
  "neovim"
  "nvchad"
)

for _tool in "${EDITOR_COMPONENTS[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool
_register_safe_reinstall_handlers editor "${EDITOR_COMPONENTS[@]}"

_batch_editor() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#EDITOR_COMPONENTS[@]}
  local current=0
  local rc

  progress_start "$total" "${action_past}ing editor components..."

  for tool in "${EDITOR_COMPONENTS[@]}"; do
    loading "${action_past^}ing ${tool}" _run_tool_lifecycle_action editor "$action" "$tool"
    rc=$?
    case $rc in 0) ((count++));; 2) :;; *) ((failed++));; esac
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  (( failed == 0 ))
}

install_all_editor_components() {
  _batch_editor "install" "install" "installed_count"
}

uninstall_all_editor_components() {
  _batch_editor "uninstall" "uninstall" "uninstalled_count"
}

update_all_editor_components() {
  _batch_editor "update" "update" "updated_count"
}

reinstall_all_editor_components() {
  _batch_editor "reinstall" "reinstall" "reinstalled_count"
}
