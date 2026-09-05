#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/tools"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"

LOG_FILE="$KARNEL_CACHE/install_npm.log"

NODE_PACKAGES=(
  "typescript"
  "nestjs"
  "prettier"
  "live-server"
  "localtunnel"
  "vercel"
  "markserv"
  "psqlformat"
  "ncu"
  "turbopack"
  "ngrok"
)

for _tool in "${NODE_PACKAGES[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool
_register_safe_reinstall_handlers npm "${NODE_PACKAGES[@]}"

import "@/utils/npm-shebang"

_batch_npm() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#NODE_PACKAGES[@]}
  local current=0
  local rc

  progress_start "$total" "${action_past}ing npm packages..."

  for tool in "${NODE_PACKAGES[@]}"; do
    loading "${action_past^}ing ${tool}" _run_tool_lifecycle_action npm "$action" "$tool"
    rc=$?
    case $rc in 0) ((count++));; 2) :;; *) ((failed++));; esac
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  (( failed == 0 ))
}

install_all_npm_packages() {
  _batch_npm "install" "install" "installed_count"
}

uninstall_all_npm_packages() {
  _batch_npm "uninstall" "uninstall" "uninstalled_count"
}

update_all_npm_packages() {
  _batch_npm "update" "update" "updated_count"
}

reinstall_all_npm_packages() {
  _batch_npm "reinstall" "reinstall" "reinstalled_count"
}
