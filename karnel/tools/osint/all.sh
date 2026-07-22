#!/usr/bin/env bash

import "@/utils/log"

OSINT_TOOLS=(
  "robin"
)

for _tool in "${OSINT_TOOLS[@]}"; do
  # shellcheck disable=SC1090
  source "$(dirname "${BASH_SOURCE[0]}")/$_tool/install.sh"
done
unset _tool

_batch_osint() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local skipped=0
  local total=${#OSINT_TOOLS[@]}
  local current=0
  local func_name

  progress_start "$total" "${action_past}ing OSINT tools..."

  for tool in "${OSINT_TOOLS[@]}"; do
    func_name="${action}_${tool//-/_}"
    if declare -f "$func_name" &>/dev/null; then
      loading "${action_past^}ing ${tool}" "$func_name"
      case $? in
        0) ((count++)) ;;
        2) ((skipped++)) ;;
        *) ((failed++)) ;;
      esac
    else
      log_error "Missing OSINT action: $func_name"
      ((failed++))
    fi
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  (( skipped > 0 )) && log_info "$skipped OSINT tool(s) already in the requested state"
  (( failed == 0 ))
}

install_all_osint() {
  _batch_osint "install" "install" "installed_count"
}

uninstall_all_osint() {
  _batch_osint "uninstall" "uninstall" "uninstalled_count"
}

update_all_osint() {
  _batch_osint "update" "update" "updated_count"
}

reinstall_all_osint() {
  _batch_osint "reinstall" "reinstall" "reinstalled_count"
}
