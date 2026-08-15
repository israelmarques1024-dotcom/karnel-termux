#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/tools"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"

LOG_FILE="$KARNEL_CACHE/install_games.log"

TOOLS_PACKAGES=(
  "buzz"
  "ctfgod"
  "detective"
  "pet-friends"
  "tamagotchi"
  "arcade"
)

for _tool in "${TOOLS_PACKAGES[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool
_register_safe_reinstall_handlers games "${TOOLS_PACKAGES[@]}"

_batch_games() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#TOOLS_PACKAGES[@]}
  local current=0
  local rc

  progress_start "$total" "${action_past}ing games..."

  for tool in "${TOOLS_PACKAGES[@]}"; do
    loading "${action_past^}ing ${tool}" _run_tool_lifecycle_action games "$action" "$tool"
    rc=$?
    case $rc in 0) ((count++));; 2) :;; *) ((failed++));; esac
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  (( failed == 0 ))
}

install_all_games() {
  _batch_games "install" "install" "installed_count"
}

uninstall_all_games() {
  _batch_games "uninstall" "uninstall" "uninstalled_count"
}

update_all_games() {
  _batch_games "update" "update" "updated_count"
}

reinstall_all_games() {
  _batch_games "reinstall" "reinstall" "reinstalled_count"
}
