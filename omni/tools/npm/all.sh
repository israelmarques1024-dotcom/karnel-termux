#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$OMNI_CACHE/install_npm.log"

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
  "ngrok"
  "turbopack"
)

for _tool in "${NODE_PACKAGES[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool

_batch_npm() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#NODE_PACKAGES[@]}
  local current=0
  local func_name

  progress_start "$total" "${action_past}ing npm packages..."

  for tool in "${NODE_PACKAGES[@]}"; do
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
