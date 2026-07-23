#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"

BACKUP_DIR="${KARNEL_DATA}/backups"

restore_main() {
  local file=""
  local cloud=false
  local list_only=false

  for arg in "$@"; do
    case "$arg" in
      --help|-h)
        echo
        box "Restore"
        echo
        log_info "Usage: karnel restore [options] [file]"
        echo
        printf "    ${D_CYAN}%-24s${NC} %s\n" "karnel restore" "Restore latest backup"
        printf "    ${D_CYAN}%-24s${NC} %s\n" "karnel restore <file>" "Restore specific backup"
        printf "    ${D_CYAN}%-24s${NC} %s\n" "karnel restore --cloud" "Restore from cloud"
        printf "    ${D_CYAN}%-24s${NC} %s\n" "karnel restore --list" "List available backups"
        echo
        return
        ;;
      --cloud) cloud=true ;;
      --list|-l) list_only=true ;;
      *)
        if [[ -z "$file" ]]; then
          if [[ -f "$arg" ]]; then
            file="$arg"
          elif [[ -f "$BACKUP_DIR/$arg" ]]; then
            file="$BACKUP_DIR/$arg"
          else
            log_error "File not found: $arg"
            return 1
          fi
        fi
        ;;
    esac
  done

  if $list_only; then
    echo
    box "Available Backups"
    echo
    local count=0
    for f in "$BACKUP_DIR"/termux-*.tar.gz "$BACKUP_DIR"/snapshot-*.tar.gz; do
      [[ -f "$f" ]] || continue
      ((count++))
      local name size csum
      name=$(basename "$f")
      size=$(du -h "$f" | awk '{print $1}')
      csum=""
      [[ -f "$f.sha256" ]] && csum="$(cut -c1-16 < "$f.sha256")..."
      printf "  ${D_GREEN}%-30s${NC} %-8s %s\n" "$name" "$size" "$csum"
    done
    [[ $count -eq 0 ]] && echo "  No backups found." && echo "  Create one: karnel backup"
    echo
    return
  fi

  if $cloud; then
    command -v rclone &>/dev/null || { log_error "Install rclone: pkg install rclone"; return 1; }
    rclone listremotes 2>/dev/null | grep -q "^karnel:" || { log_error "Run 'rclone config' and name remote 'karnel'"; return 1; }
    log_info "Downloading from cloud..."
    rclone copy "karnel:backups/" "$BACKUP_DIR/" --include "termux-*.tar.gz" 2>/dev/null
    log_success "Downloaded from cloud"
  fi

  [[ -z "$file" ]] && file=$(ls -t "$BACKUP_DIR"/termux-*.tar.gz 2>/dev/null | head -1)
  [[ -z "$file" || ! -f "$file" ]] && { log_error "No backup found. Run 'karnel backup' first"; return 1; }

  local ts
  ts=$(basename "$file" .tar.gz | sed 's/termux-//')
  local pkgs="$BACKUP_DIR/packages-$ts.list"
  local manifest="$BACKUP_DIR/manifest-$ts.list"

  echo
  box "Restore: $(basename "$file")"
  echo
  log_info "Size: $(du -h "$file" | awk '{print $1}')"
  log_info "Date: $(date -r "$file" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)"
  [[ -f "$manifest" ]] && log_info "$(wc -l < "$manifest") tools to reinstall"
  [[ -f "$pkgs" ]] && log_info "$(wc -l < "$pkgs") packages to restore"

  # Checksum
  local checksum_file="$file.sha256"
  if [[ -f "$checksum_file" ]]; then
    if sha256sum -c "$checksum_file" &>/dev/null; then
      log_success "Checksum verified"
    else
      log_error "Checksum mismatch! Backup may be corrupted"
      read_confirm "Continue anyway?" confirm
      [[ "$confirm" != "y" ]] && { log_info "Cancelled"; return 1; }
    fi
  fi

  echo
  read_confirm "Proceed with restore?" confirm
  [[ "$confirm" != "y" ]] && { log_info "Cancelled"; return 0; }

  local tmp
  tmp=$(mktemp -d)
  tar -xzf "$file" -C "$tmp" 2>/dev/null

  # Configs
  if [[ -d "$tmp/config/home" ]]; then
    log_info "Restoring shell configs..."
    for f in "$tmp/config/home/"*; do
      [[ -f "$f" ]] && cp "$f" "$HOME/$(basename "$f")" 2>/dev/null
    done
    log_success "Shell configs restored"
  fi

  if [[ -d "$tmp/config/termux" ]]; then
    log_info "Restoring Termux configs..."
    cp -r "$tmp/config/termux/." "$HOME/.termux/" 2>/dev/null
    termux-reload-settings 2>/dev/null || true
    log_success "Termux configs restored"
  fi

  if [[ -d "$tmp/config/ssh" ]]; then
    log_info "Restoring SSH keys..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    for f in "$tmp/config/ssh/"*; do
      [[ -f "$f" ]] && cp "$f" "$HOME/.ssh/$(basename "$f")" 2>/dev/null
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
    while IFS=: read -r mod tool; do
      ((total++))
      karnel install "$mod" "--$tool" &>/dev/null && ((ok++))
    done < "$manifest"
    log_success "$ok/$total tools reinstalled"
  fi

  echo
  log_success "Done! Restart Termux or run: source ~/.zshrc"
  echo
}
