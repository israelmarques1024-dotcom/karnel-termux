#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/tools"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"

LOG_FILE="$KARNEL_CACHE/install_deploy.log"

DEPLOY_TOOLS=("railway" "netlify" "vercel" "supabase")

for _tool in "${DEPLOY_TOOLS[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool
_register_safe_reinstall_handlers deploy "${DEPLOY_TOOLS[@]}"

_batch_deploy() {
  local action="$1"
  local action_past="$2"
  local count_var="${3:-DEPLOY_COUNT}"
  local count=0
  local failed=0
  local total=${#DEPLOY_TOOLS[@]}
  local current=0
  local rc

  progress_start "$total" "${action_past}ing deploy tools..."

  for tool in "${DEPLOY_TOOLS[@]}"; do
    loading "${action_past^}ing $tool" _run_tool_lifecycle_action deploy "$action" "$tool"
    rc=$?
    case $rc in 0) ((count++));; 2) :;; *) ((failed++));; esac
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  (( failed == 0 ))
}

install_all_deploy_tools() { _batch_deploy "install" "install"; }
uninstall_all_deploy_tools() { _batch_deploy "uninstall" "uninstall"; }
update_all_deploy_tools() { _batch_deploy "update" "update"; }
reinstall_all_deploy_tools() { _batch_deploy "reinstall" "reinstall"; }
