#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$KARNEL_CACHE/install_dev.log"

TOOLS_PACKAGES=(
  "gh"
  "wget"
  "curl"
  "lsd"
  "bat"
  "proot"
  "ncurses"
  "tmate"
  "openssh"
  "tmux"
  "cloudflared"
  "translate"
  "html2text"
  "jq"
  "bc"
  "tree"
  "fzf"
  "imagemagick"
  "shfmt"
  "make"
  "udocker"
  "snyk"
  "httptmux"
  "zork"
  "fconv"
  "filecheck"
  "websites"
  "notes"
  "treex"
  "passman"
  "applaunch"
  "splash"
)

for _tool in "${TOOLS_PACKAGES[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool

_batch_dev() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#TOOLS_PACKAGES[@]}
  local current=0
  local func_name

  progress_start "$total" "${action_past}ing dev tools..."

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
  eval "$count_var=$count"
  return $failed
}

install_all_dev() {
  _batch_dev "install" "install" "installed_count"
}

uninstall_all_dev() {
  _batch_dev "uninstall" "uninstall" "uninstalled_count"
}

update_all_dev() {
  _batch_dev "update" "update" "updated_count"
}

reinstall_all_dev() {
  _batch_dev "reinstall" "reinstall" "reinstalled_count"
}
