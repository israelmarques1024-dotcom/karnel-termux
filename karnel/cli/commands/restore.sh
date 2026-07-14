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

  # Configs — extract to temp then copy to correct locations
  local tmp
  tmp=$(mktemp -d)
  tar -xzf "$file" -C "$tmp" 2>/dev/null

  if [[ -d "$tmp/config/home" ]]; then
    log_info "Restoring shell configs..."
    for f in "$tmp/config/home/"*; do
      cp "$f" "$HOME/$(basename "$f")" 2>/dev/null
    done
    log_success "Shell configs restored"
  fi

  if [[ -d "$tmp/config/termux" ]]; then
    log_info "Restoring Termux configs..."
    cp -r "$tmp/config/termux/.termux" "$HOME/" 2>/dev/null
    log_success "Termux configs restored"
  fi

  if [[ -d "$tmp/config/ssh" ]]; then
    log_info "Restoring SSH keys..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    for f in "$tmp/config/ssh/"*; do
      cp "$f" "$HOME/.ssh/$(basename "$f")" 2>/dev/null
    done
    chmod 600 "$HOME/.ssh/id_"* 2>/dev/null
    log_success "SSH keys restored"
  fi

  if [[ -d "$tmp/config/config" ]]; then
    log_info "Restoring .config..."
    cp -r "$tmp/config/config/"* "$HOME/.config/" 2>/dev/null
    log_success ".config restored"
  fi

  if [[ -d "$tmp/config/prefix-etc" ]]; then
    log_info "Restoring apt sources..."
    cp "$tmp/config/prefix-etc/"* "$PREFIX/etc/apt/" 2>/dev/null
    log_success "APT sources restored"
  fi

  rm -rf "$tmp"
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
