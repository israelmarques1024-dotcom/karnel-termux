#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/tools"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"

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
)

TOOLS_DISPLAY=(
  "GitHub CLI"
  "Wget"
  "Curl"
  "LSD (ls replacement)"
  "Bat (cat replacement)"
  "Proot (chroot alternative)"
  "Ncurses Utils"
  "Tmate (terminal sharing)"
  "OpenSSH"
  "Tmux"
  "Cloudflared (Cloudflare Tunnel)"
  "Translate Shell"
  "html2text (HTML to text converter)"
  "jq (JSON processor)"
  "bc (calculator)"
  "Tree (directory listing)"
  "Fzf (fuzzy finder)"
  "ImageMagick (image manipulation)"
  "Shfmt (shell script formatter)"
  "Make (build automation)"
  "Udocker (container management)"
  "Snyk (security scanner)"
)

for _tool in "${TOOLS_PACKAGES[@]}"; do
  # shellcheck disable=SC1090
  source "$(dirname "${BASH_SOURCE[0]}")/$_tool/install.sh"
done
unset _tool
_register_safe_reinstall_handlers dev "${TOOLS_PACKAGES[@]}"

declare -gA _INSTALL_RESULTS

_batch_dev() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local count=0
  local failed=0
  local total=${#TOOLS_PACKAGES[@]}
  local current=0
  local rc

  _INSTALL_RESULTS=()
  progress_start "$total" "${action_past}ing dev tools..."

  for tool in "${TOOLS_PACKAGES[@]}"; do
    loading "${action_past^}ing ${tool}" _run_tool_lifecycle_action dev "$action" "$tool"
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
