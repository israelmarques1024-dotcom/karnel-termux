#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/tools"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"

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
  "superfile"
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
  "SuperFile (terminal file manager)"
)

for _tool in "${TOOLS_PACKAGES[@]}"; do
  source "$(dirname "${BASH_SOURCE[0]}")/$_tool/install.sh"
done
unset _tool
_register_safe_reinstall_handlers utils "${TOOLS_PACKAGES[@]}"

declare -gA _INSTALL_RESULTS

_batch_utils() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#TOOLS_PACKAGES[@]}
  local current=0
  local rc

  _INSTALL_RESULTS=()
  progress_start "$total" "${action_past}ing utility tools..."

  for tool in "${TOOLS_PACKAGES[@]}"; do
    loading "${action_past^}ing ${tool}" _run_tool_lifecycle_action utils "$action" "$tool"
    rc=$?
    _INSTALL_RESULTS["$tool"]=$rc
    case $rc in
      0) ((count++));;
      2) :;;
      *) ((failed++));;
    esac
    ((current++))
    progress_update "$current" "$total"
  done

  progress_done "$total"
  printf -v "$count_var" '%s' "$count"
  (( failed == 0 ))
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
