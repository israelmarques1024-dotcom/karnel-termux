# shellcheck shell=bash

import "@/utils/tools"
import "@/utils/install"
declare -f _run_tool_lifecycle_action &>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/../../utils/tools.sh"

SECURITY_TOOLS=(
  "nmap"
  "hydra"
  "nikto"
  "sqlmap"
  "gobuster"
  "dirb"
  "wpscan"
  "john"
  "aircrack-ng"
  "metasploit"
  "burpsuite"
  "zap"
  "enum4linux"
  "smbclient"
  "ffuf"
  "whatweb"
  "wafw00f"
  "dnsrecon"
  "theharvester"
  "subfinder"
  "amass"
  "masscan"
  "netcat"
  "tcpdump"
  "whois"
  "hashcat"
  "binwalk"
  "foremost"
  "steghide"
  "exiftool"
)

for _tool in "${SECURITY_TOOLS[@]}"; do
  source "$(dirname "${BASH_SOURCE[0]}")/$_tool/install.sh"
done
unset _tool
_register_safe_reinstall_handlers security "${SECURITY_TOOLS[@]}"

_batch_security() {
  local action="$1"
  local action_past="$2"
  local count_var="$3"
  local skipped_var="${4:-_unused}"
  local failed_var="${5:-_unused}"
  local count=0
  local skipped=0
  local failed=0
  local rc
  for tool in "${SECURITY_TOOLS[@]}"; do
    loading "${action_past^}ing ${tool}" _run_tool_lifecycle_action security "$action" "$tool"
    rc=$?
    case $rc in
      0) ((count += 1));;
      2) ((skipped += 1));;
      *) ((failed += 1));;
    esac
  done
  if [[ "$count_var" != "_unused" ]]; then
    printf -v "$count_var" '%s' "$count"
  fi
  if [[ "$skipped_var" != "_unused" ]]; then
    printf -v "$skipped_var" '%s' "$skipped"
  fi
  if [[ "$failed_var" != "_unused" ]]; then
    printf -v "$failed_var" '%s' "$failed"
  fi
  (( failed == 0 ))
}

install_all_security() {
  local installed_count=0 skipped_count=0 failed_count=0
  local rc=0
  _batch_security "install" "install" installed_count skipped_count failed_count || rc=$?
  echo
  log_success "Security: $installed_count installed, $skipped_count skipped, $failed_count failed"
  return "$rc"
}

uninstall_all_security() { _batch_security "uninstall" "uninstall" _unused; }
update_all_security()   { _batch_security "update" "update" _unused; }
reinstall_all_security() { _batch_security "reinstall" "reinstall" _unused; }
