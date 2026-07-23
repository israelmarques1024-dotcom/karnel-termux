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

_batch_security() {
  local action="$1"
  local action_past="$2"
  local -n count_var="$3"
  for tool in "${SECURITY_TOOLS[@]}"; do
    func_name="${action}_${tool//-/_}"
    loading "${action_past^}ing ${tool}" "$func_name"
    case $? in
      0) ((count_var++)) ;;
      2) ((skipped_count++)) ;;
      1) ((failed_count++)) ;;
    esac
  done
}

install_all_security() {
  local installed_count=0 skipped_count=0 failed_count=0
  _batch_security "install" "install" installed_count
  echo
  log_success "Security: $installed_count installed, $skipped_count skipped, $failed_count failed"
}

uninstall_all_security() { _batch_security "uninstall" "uninstall" _unused; }
update_all_security()   { _batch_security "update" "update" _unused; }
reinstall_all_security() { _batch_security "reinstall" "reinstall" _unused; }
