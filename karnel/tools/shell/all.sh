#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$KARNEL_CACHE/install_shell.log"
ZSH_PLUGINS_DIR="$HOME/.zsh-plugins"

SHELL_PLUGINS=(
  "powerlevel10k"
  "zsh-defer"
  "zsh-autosuggestions"
  "zsh-syntax-highlighting"
  "history-substring"
  "zsh-completions"
  "fzf-tab"
  "you-should-use"
  "zsh-autopair"
  "better-npm"
)

for _tool in "${SHELL_PLUGINS[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool

_batch_shell() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#SHELL_PLUGINS[@]}
  local current=0
  local func_name

  progress_start "$total" "${action_past}ing shell plugins..."

  for tool in "${SHELL_PLUGINS[@]}"; do
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

install_all_shell_plugins() {
  _batch_shell "install" "install" "installed_count"
}

uninstall_all_shell_plugins() {
  _batch_shell "uninstall" "uninstall" "uninstalled_count"
}

update_all_shell_plugins() {
  _batch_shell "update" "update" "updated_count"
}

reinstall_all_shell_plugins() {
  _batch_shell "reinstall" "reinstall" "reinstalled_count"
}
