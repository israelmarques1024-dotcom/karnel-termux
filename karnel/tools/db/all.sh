#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/tools"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"

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
_register_safe_reinstall_handlers db "${DB_TOOLS[@]}"

_batch_db() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#DB_TOOLS[@]}
  local current=0
  local rc

  progress_start "$total" "${action_past}ing DB tools..."

  for tool in "${DB_TOOLS[@]}"; do
    loading "${action_past^}ing ${tool}" _run_tool_lifecycle_action db "$action" "$tool"
    rc=$?
    case $rc in 0) ((count++));; 2) :;; *) ((failed++));; esac
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  (( failed == 0 ))
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
