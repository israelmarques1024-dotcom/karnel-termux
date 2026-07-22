#!/usr/bin/env bash

import "@/utils/log"

LOG_FILE="$KARNEL_CACHE/install_utils.log"

TOOLS_PACKAGES=(
  "fconv"
  "filecheck"
  "websites"
  "notes"
  "treex"
  "passman"
  "applaunch"
  "splash"
  "httptmux"
  "zork"
  "qrcode"
)

TOOLS_DISPLAY=(
  "Fconv (file converter)"
  "Filecheck (file integrity)"
  "Websites (project scaffold)"
  "Notes (terminal notes)"
  "Treex (tree explorer)"
  "Passman (password manager)"
  "Applaunch (app launcher)"
  "Splash (startup splash)"
  "httptmux (interactive API client)"
  "Zork (text adventure games I, II, III)"
  "QR Code (link-to-QR generator)"
)

for _tool in "${TOOLS_PACKAGES[@]}"; do
  source "$(dirname "${BASH_SOURCE[0]}")/$_tool/install.sh"
done
unset _tool

declare -gA _INSTALL_RESULTS

_batch_utils() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#TOOLS_PACKAGES[@]}
  local current=0
  local func_name

  _INSTALL_RESULTS=()
  progress_start "$total" "${action_past}ing utility tools..."

  for tool in "${TOOLS_PACKAGES[@]}"; do
    func_name="${action}_${tool//-/_}"
    if declare -f "$func_name" &>/dev/null; then
      loading "${action_past^}ing ${tool}" "$func_name"
      _INSTALL_RESULTS["$tool"]=$?
      case ${_INSTALL_RESULTS["$tool"]} in
        0) ((count++));;
        1) ((failed++));;
      esac
    fi
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  return $failed
}

install_all_utils() {
  _batch_utils "install" "install" "installed_count"
}

uninstall_all_utils() {
  _batch_utils "uninstall" "uninstall" "uninstalled_count"
}

update_all_utils() {
  _batch_utils "update" "update" "updated_count"
}

reinstall_all_utils() {
  _batch_utils "reinstall" "reinstall" "reinstalled_count"
}
