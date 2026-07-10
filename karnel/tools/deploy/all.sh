#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$KARNEL_CACHE/install_deploy.log"

DEPLOY_TOOLS=("vercel" "railway" "netlify")

for _tool in "${DEPLOY_TOOLS[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool

_batch_deploy() {
  local action="$1"
  local action_past="$2"
  local count_var="${3:-DEPLOY_COUNT}"
  local count=0
  local failed=0
  local total=${#DEPLOY_TOOLS[@]}
  local current=0

  progress_start "$total" "${action_past}ing deploy tools..."

  for tool in "${DEPLOY_TOOLS[@]}"; do
    local func_name="${action}_${tool//-/_}"
    if declare -f "$func_name" &>/dev/null; then
      loading "${action_past^}ing $tool" "$func_name"
      case $? in 0) ((count++));; 1) ((failed++));; esac
    fi
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  eval "$count_var=$count"
  return $failed
}

install_all_deploy_tools() { _batch_deploy "install" "install"; }
uninstall_all_deploy_tools() { _batch_deploy "uninstall" "uninstall"; }
update_all_deploy_tools() { _batch_deploy "update" "update"; }
reinstall_all_deploy_tools() { _batch_deploy "reinstall" "reinstall"; }
