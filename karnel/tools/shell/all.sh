#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/tools"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"
import "@/utils/uninstall"

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
_register_safe_reinstall_handlers shell "${SHELL_PLUGINS[@]}"

_batch_shell() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#SHELL_PLUGINS[@]}
  local current=0
  local rc

  progress_start "$total" "${action_past}ing shell plugins..."

  for tool in "${SHELL_PLUGINS[@]}"; do
    if [[ "$action" == "uninstall" ]]; then
      _run_tool_lifecycle_action shell "$action" "$tool"
    else
      loading "${action_past^}ing ${tool}" _run_tool_lifecycle_action shell "$action" "$tool"
    fi
    rc=$?
    case $rc in 0) ((count++));; 2) :;; *) ((failed++));; esac
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  (( failed == 0 ))
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
