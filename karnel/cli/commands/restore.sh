#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

restore_main() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo
    box "◈ KARNEL RESTORE ◈"
    echo
    list_item "karnel restore                  Restore latest backup"
    list_item "karnel restore <arquivo>        Restore specific file"
    list_item "karnel restore --cloud          Restore from Google Drive"
    echo
    return
  fi

  local dir="${KARNEL_DATA}/backups"
  local file=""
  local cloud=false

  for arg in "$@"; do
    [[ "$arg" == "--cloud" ]] && cloud=true && continue
    [[ -f "$arg" ]] && file="$arg"
  done

  # Download from cloud
  if $cloud; then
    command -v rclone &>/dev/null || { log_error "Install rclone: pkg install rclone"; return 1; }
    rclone listremotes 2>/dev/null | grep -q "^karnel:" || { log_error "Run 'rclone config' and name remote 'karnel'"; return 1; }

    log_info "Downloading from Google Drive..."
    rclone copy "karnel:backups/" "$dir/" --include "termux-*.tar.gz" 2>/dev/null
  fi

  # Find file
  [[ -z "$file" ]] && file=$(ls -t "$dir"/termux-*.tar.gz 2>/dev/null | head -1)
  [[ -z "$file" || ! -f "$file" ]] && { log_error "No backup found. Run 'karnel backup' first"; return 1; }

  local ts
  ts=$(basename "$file" .tar.gz | sed 's/termux-//')
  local pkgs="$dir/packages-$ts.list"
  local manifest="$dir/manifest-$ts.list"

  echo
  box "◈ KARNEL RESTORE ◈"
  echo
  log_info "Restoring: $(basename "$file")"
  [[ -f "$manifest" ]] && log_info "$(wc -l < "$manifest") tools to reinstall"
  echo

  read_confirm "Proceed with restore?" confirm
  [[ "$confirm" != "y" ]] && { log_info "Cancelled"; return 0; }

  # Configs
  log_info "Restoring configs..."
  tar -xzf "$file" -C / 2>/dev/null
  log_success "Configs restored"

  # Packages
  if [[ -f "$pkgs" ]]; then
    log_info "Restoring packages..."
    dpkg --set-selections < "$pkgs" 2>/dev/null
    apt-get dselect-upgrade -y &>/dev/null &
    log_success "Package list restored"
  fi

  # Tools
  if [[ -f "$manifest" ]]; then
    log_info "Reinstalling tools..."
    local ok=0 total=0
    while IFS= read -r line; do
      ((total++))
      local mod="${line%%:*}" tool="${line#*:}"
      karnel install "$mod" "--$tool" &>/dev/null && ((ok++))
    done < "$manifest"
    log_success "$ok/$total tools reinstalled"
  fi

  echo
  log_success "All done! Restart Termux or run: source ~/.zshrc"
  echo
}
