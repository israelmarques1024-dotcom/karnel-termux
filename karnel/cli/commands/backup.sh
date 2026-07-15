#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

backup_main() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo
    box "◈ KARNEL BACKUP ◈"
    echo
    log_info "Save ALL your Termux configs + installed tools"
    echo
    list_item "karnel backup                  Backup local"
    list_item "karnel backup --cloud           Backup + upload to Google Drive"
    list_item "karnel restore                  Restore latest backup"
    list_item "karnel restore --cloud          Restore from Google Drive"
    echo
    return
  fi

  local cloud=false
  [[ "$1" == "--cloud" ]] && cloud=true

  local dir="${KARNEL_DATA}/backups"
  mkdir -p "$dir"
  local ts
  ts=$(date +%Y%m%d_%H%M%S)
  local file="$dir/termux-$ts.tar.gz"

  echo
  box "◈ KARNEL BACKUP ◈"
  echo

  # Package list
  dpkg --get-selections > "$dir/packages-$ts.list" 2>/dev/null
  local pkgs
  pkgs=$(wc -l < "$dir/packages-$ts.list")
  log_success "Saved $pkgs installed packages"

  # Karnel tool manifest
  local tools=()
  for m in "$KARNEL_PATH/tools/"*/; do
    local mod
    mod=$(basename "${m%/}")
    for t in "$m"*/; do
      local tool
      tool=$(basename "${t%/}")
      local bins
      bins=$(grep "\"$tool:" "$m/all.sh" 2>/dev/null | cut -d: -f3 | tr -d '"')
      local found=false
      for b in ${bins//,/ }; do
        command -v "$b" &>/dev/null && found=true && break
      done
      $found && tools+=("$mod:$tool")
    done
  done
  printf "%s\n" "${tools[@]}" > "$dir/manifest-$ts.list"
  log_success "Saved ${#tools[@]} Karnel tools"

  # Configs
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/config"/{home,termux,ssh,config,prefix-etc}

  for f in .bashrc .zshrc .profile .zshenv .inputrc; do
    [[ -f "$HOME/$f" ]] && cp "$HOME/$f" "$tmp/config/home/"
  done
  [[ -d "$HOME/.termux" ]] && cp -r "$HOME/.termux" "$tmp/config/termux/" 2>/dev/null
  [[ -d "$HOME/.ssh" ]] && cp "$HOME/.ssh/id_"* "$HOME/.ssh/config" "$HOME/.ssh/known_hosts" "$tmp/config/ssh/" 2>/dev/null
  for d in "$HOME/.config"/*; do
    if [[ -d "$d" ]]; then
      local base; base=$(basename "$d")
      if [[ "$base" != "github-copilot" && "$base" != "nvm" && "$base" != "coc" && "$base" != "Code" && "$base" != "yarn" ]]; then
        cp -r "$d" "$tmp/config/config/" 2>/dev/null
      fi
    fi
  done
  [[ -f "$PREFIX/etc/apt/sources.list" ]] && cp "$PREFIX/etc/apt/sources.list" "$tmp/config/prefix-etc/" 2>/dev/null

  tar -czf "$file" -C "$tmp" . 2>/dev/null
  rm -rf "$tmp"

  local size
  size=$(du -h "$file" | awk '{print $1}')
  log_success "Backup: $(basename "$file") ($size)"

  # Cloud
  if $cloud; then
    if ! command -v rclone &>/dev/null; then
      pkg install rclone -y &>/dev/null || log_warn "Install rclone: pkg install rclone"
    fi
    if command -v rclone &>/dev/null; then
      if rclone listremotes 2>/dev/null | grep -q "^karnel:"; then
        loading "Uploading" rclone copy "$file" "karnel:backups/"
        log_success "Uploaded to Google Drive"
      else
        log_warn "Run 'rclone config' and name the remote 'karnel'"
      fi
    fi
  fi

  echo
  log_success "Done! Restore with: karnel restore"
  echo
}
