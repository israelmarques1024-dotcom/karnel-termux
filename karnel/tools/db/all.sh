#!/usr/bin/env bash

LOG_FILE="$KARNEL_CACHE/install_db.log"

DB_TOOLS=(
  "postgresql"
  "mariadb"
  "sqlite"
  "mongodb"
  "redis"
)

for _tool in "${DB_TOOLS[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool

_batch_db() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#DB_TOOLS[@]}
  local current=0
  local func_name

  progress_start "$total" "${action_past}ing DB tools..."

  for tool in "${DB_TOOLS[@]}"; do
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

install_all_db_tools() {
  _batch_db "install" "install" "installed_count"
}

uninstall_all_db_tools() {
  _batch_db "uninstall" "uninstall" "uninstalled_count"
}

update_all_db_tools() {
  _batch_db "update" "update" "updated_count"
}

reinstall_all_db_tools() {
  _batch_db "reinstall" "reinstall" "reinstalled_count"
}
