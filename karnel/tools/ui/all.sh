#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$KARNEL_CACHE/install_ui.log"
TERMUX_DIR="$HOME/.termux"

UI_COMPONENTS=(
  "font"
  "extra-keys"
  "cursor"
  "banner"
)

for _tool in "${UI_COMPONENTS[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool

_batch_ui() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#UI_COMPONENTS[@]}
  local current=0
  local func_name

  progress_start "$total" "${action_past}ing UI components..."

  for tool in "${UI_COMPONENTS[@]}"; do
    func_name="${action}_${tool//-/_}"
    if declare -f "$func_name" &>/dev/null; then
      loading "${action_past^}ing ${tool}" "$func_name"
      case $? in 0) ((count++));; 1) ((failed++));; esac
    fi
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  return $failed
}

install_all_ui_components() {
  _batch_ui "install" "install" "installed_count"
}

uninstall_all_ui_components() {
  _batch_ui "uninstall" "uninstall" "uninstalled_count"
}

update_all_ui_components() {
  _batch_ui "update" "update" "updated_count"
}

reinstall_all_ui_components() {
  _batch_ui "reinstall" "reinstall" "reinstalled_count"
}
