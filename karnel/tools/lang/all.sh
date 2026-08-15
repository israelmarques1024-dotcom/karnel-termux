#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/tools"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"

LOG_FILE="$KARNEL_CACHE/install_lang.log"

LANGUAGE_PACKAGES=(
  "bun"
  "nodejs"
  "python"
  "perl"
  "php"
  "rust"
  "clang"
  "golang"
)

for _tool in "${LANGUAGE_PACKAGES[@]}"; do
  source "$(dirname "$BASH_SOURCE")/$_tool/install.sh"
done
unset _tool
_register_safe_reinstall_handlers lang "${LANGUAGE_PACKAGES[@]}"

_batch_lang() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#LANGUAGE_PACKAGES[@]}
  local current=0
  local rc

  progress_start "$total" "${action_past}ing language packages..."

  for tool in "${LANGUAGE_PACKAGES[@]}"; do
    loading "${action_past^}ing ${tool}" _run_tool_lifecycle_action lang "$action" "$tool"
    rc=$?
    case $rc in 0) ((count++));; 2) :;; *) ((failed++));; esac
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  (( failed == 0 ))
}

install_all_lang_packages() {
  _batch_lang "install" "install" "installed_count"
}

uninstall_all_lang_packages() {
  _batch_lang "uninstall" "uninstall" "uninstalled_count"
}

update_all_lang_packages() {
  _batch_lang "update" "update" "updated_count"
}

reinstall_all_lang_packages() {
  _batch_lang "reinstall" "reinstall" "reinstalled_count"
}
