#!/usr/bin/env bash

import "@/utils/log"

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

_batch_lang() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#LANGUAGE_PACKAGES[@]}
  local current=0
  local func_name

  progress_start "$total" "${action_past}ing language packages..."

  for tool in "${LANGUAGE_PACKAGES[@]}"; do
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
