#!/usr/bin/env bash

import "@/utils/log"

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

_batch_games() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#TOOLS_PACKAGES[@]}
  local current=0
  local func_name

  progress_start "$total" "${action_past}ing games..."

  for tool in "${TOOLS_PACKAGES[@]}"; do
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
