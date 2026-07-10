#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$KARNEL_CACHE/install_auto.log"

AUTOMATION_TOOLS=(
  "n8n"
)

for _tool in "${AUTOMATION_TOOLS[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool

_batch_auto() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#AUTOMATION_TOOLS[@]}
  local current=0
  local func_name

  progress_start "$total" "${action_past}ing automation tools..."

  for tool in "${AUTOMATION_TOOLS[@]}"; do
    func_name="${action}_${tool//-/_}"
    if declare -f "$func_name" &>/dev/null; then
      loading "${action_past^}ing ${tool}" "$func_name"
      case $? in 0) ((count++));; 1) ((failed++));; esac
    fi
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  eval "$count_var=$count"
  return $failed
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
