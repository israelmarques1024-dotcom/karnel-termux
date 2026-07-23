#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/tools/osint/robin/common"

BACKUP_DIR="${KARNEL_DATA}/backups"
mkdir -p "$BACKUP_DIR"

backup_main() {
  local cmd="${1:-}"
  shift 2>/dev/null || true

  case "$cmd" in
    --help|-h)      backup_help ;;
    list|ls)        backup_list ;;
    info|show)      backup_info "$@" ;;
    snapshot)       backup_snapshot "$@" ;;
    --cron)         backup_cron ;;
    --cloud)        backup_run true ;;
    restore)        backup_restore "$@" ;;
    *)              backup_run false ;;
  esac
}

backup_help() {
  echo
  box "Backup & Restore"
  echo
  log_info "Usage: karnel backup [subcommand]"
  echo
  separator_section "Subcommands"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "backup" "Create a new backup"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "backup --cloud" "Backup + upload to cloud"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "backup snapshot <n>" "Named snapshot"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "backup list" "List all backups"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "backup info <file>" "Show backup contents"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "backup --cron" "Run automated daily backup"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "restore" "Restore latest backup"
  printf "    ${D_CYAN}%-20s${NC} %s\n" "restore <file>" "Restore specific backup"
  echo
  separator_section "Examples"
  echo "  karnel backup"
  echo "  karnel backup snapshot before-update"
  echo "  karnel backup list"
  echo "  karnel restore"
  echo "  karnel restore termux-20240723_120000.tar.gz"
  echo
}

backup_run() {
  local cloud="${1:-false}"
  local ts
  ts=$(date +%Y%m%d_%H%M%S)
  local file="$BACKUP_DIR/termux-$ts.tar.gz"

  echo
  box "Karnel Backup"
  echo

  # Package list
  dpkg --get-selections > "$BACKUP_DIR/packages-$ts.list" 2>/dev/null
  local pkgs
  pkgs=$(wc -l < "$BACKUP_DIR/packages-$ts.list")
  log_success "Saved $pkgs installed packages"

  # Karnel tool manifest
  local -a tools=()
  for m in "$KARNEL_PATH/tools/"*/; do
    local mod
    mod=$(basename "${m%/}")
    for t in "$m"*/; do
      local tool
      tool=$(basename "${t%/}")
      [[ "$tool" == "all.sh" ]] && continue
      local found=false
      for f in "$t"/*.sh; do
        [[ -f "$f" ]] && found=true && break
      done
      $found && tools+=("$mod:$tool")
    done
  done
  printf "%s\n" "${tools[@]}" > "$BACKUP_DIR/manifest-$ts.list"
  log_success "Saved ${#tools[@]} Karnel tools"

  # Configs
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/config"/{home,termux,ssh,config,prefix-etc,env}

  for f in .bashrc .zshrc .profile .zshenv .inputrc; do
    [[ -f "$HOME/$f" ]] && cp "$HOME/$f" "$tmp/config/home/"
  done
  [[ -d "$HOME/.termux" ]] && cp -r "$HOME/.termux" "$tmp/config/termux/" 2>/dev/null
  if [[ -d "$HOME/.ssh" ]]; then
    log_warn "Including SSH keys in backup — these are sensitive!"
    mkdir -p "$tmp/config/ssh"
    cp "$HOME/.ssh/id_"* "$HOME/.ssh/config" "$HOME/.ssh/known_hosts" "$tmp/config/ssh/" 2>/dev/null
  fi

  # Karnel env vars
  env | grep -E '^(KARNEL_|OPENAI_|ANTHROPIC_|GEMINI_|GROQ_)' > "$tmp/config/env/karnel.env" 2>/dev/null
  log_info "Saved environment variables"

  for d in "$HOME/.config"/*; do
    if [[ -d "$d" ]]; then
      local base; base=$(basename "$d")
      if [[ "$base" != "github-copilot" && "$base" != "nvm" && "$base" != "coc" && "$base" != "Code" && "$base" != "yarn" ]]; then
        cp -r "$d" "$tmp/config/config/" 2>/dev/null
      fi
    fi
  done

  if [[ "$ROBIN_CONFIG_DIR" == "$HOME/.config/"* ]]; then
    local robin_config_relative="${ROBIN_CONFIG_DIR#"$HOME/.config/"}"
    rm -f "$tmp/config/config/$robin_config_relative"/.env* 2>/dev/null
  fi
  find "$tmp/config/config" -type f -path '*/karnel/robin/.env*' -delete 2>/dev/null
  [[ -f "$PREFIX/etc/apt/sources.list" ]] && cp "$PREFIX/etc/apt/sources.list" "$tmp/config/prefix-etc/" 2>/dev/null

  tar -czf "$file" -C "$tmp" . 2>/dev/null
  rm -rf "$tmp"

  local size checksum
  size=$(du -h "$file" | awk '{print $1}')
  checksum=$(sha256sum "$file" | awk '{print $1}')
  echo "$checksum" > "$file.sha256"
  log_success "Backup: $(basename "$file") ($size)"
  log_success "Checksum (SHA256): ${checksum:0:16}...${checksum: -16}"

  if $cloud; then
    _backup_cloud "$file"
  fi

  echo
  log_success "Done! Restore with: karnel restore"
  echo
}

backup_snapshot() {
  local name="${1:-manual}"
  local file="$BACKUP_DIR/snapshot-$name.tar.gz"
  local ts
  ts=$(date +%Y%m%d_%H%M%S)

  echo
  box "Karnel Snapshot: $name"
  echo

  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/config"/{home,termux,config}

  for f in .bashrc .zshrc .profile; do
    [[ -f "$HOME/$f" ]] && cp "$HOME/$f" "$tmp/config/home/"
  done
  [[ -d "$HOME/.termux" ]] && cp -r "$HOME/.termux" "$tmp/config/termux/" 2>/dev/null
  for d in "$HOME/.config"/*; do
    [[ -d "$d" ]] && cp -r "$d" "$tmp/config/config/" 2>/dev/null
  done

  echo "$ts" > "$tmp/meta-snapshot.txt"
  echo "$name" >> "$tmp/meta-snapshot.txt"

  dpkg --get-selections > "$tmp/packages.list" 2>/dev/null
  log_info "Snapshot includes $(wc -l < "$tmp/packages.list") packages"

  tar -czf "$file" -C "$tmp" . 2>/dev/null
  rm -rf "$tmp"

  local checksum
  checksum=$(sha256sum "$file" | awk '{print $1}')
  echo "$checksum" > "$file.sha256"
  log_success "Snapshot '$name' saved ($(du -h "$file" | awk '{print $1}'))"
}

backup_list() {
  echo
  box "Backups"
  echo
  local -a files=()
  for f in "$BACKUP_DIR"/termux-*.tar.gz "$BACKUP_DIR"/snapshot-*.tar.gz; do
    [[ -f "$f" ]] || continue
    files+=("$f")
  done
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "  No backups found."
    echo "  Create one: karnel backup"
    return
  fi
  printf "${D_CYAN}%-30s${NC} ${D_GREEN}%-8s${NC} %s\n" "FILE" "SIZE" "CHECKSUM"
  echo "  $(printf '%0.s-' {1..70})"
  for f in "${files[@]}"; do
    local name size csum
    name=$(basename "$f")
    size=$(du -h "$f" | awk '{print $1}')
    csum=""
    [[ -f "$f.sha256" ]] && csum="$(cut -c1-16 < "$f.sha256")..."
    printf "  %-30s %-8s %s\n" "$name" "$size" "$csum"
  done
  echo
  log_info "Total: ${#files[@]} backup(s)"
}

backup_info() {
  local file="${1:-}"
  if [[ -z "$file" ]]; then
    # Find latest
    file=$(ls -t "$BACKUP_DIR"/termux-*.tar.gz 2>/dev/null | head -1)
    [[ -z "$file" ]] && log_error "No backups found" && return 1
  fi
  [[ "$file" != /* ]] && file="$BACKUP_DIR/$file"
  [[ ! -f "$file" ]] && log_error "Backup not found: $file" && return 1

  echo
  box "Backup Info: $(basename "$file")"
  echo
  log_info "Size: $(du -h "$file" | awk '{print $1}')"
  log_info "Created: $(date -r "$file" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)"
  [[ -f "$file.sha256" ]] && log_info "SHA256: $(cat "$file.sha256")"
  echo
  separator_section "Contents"
  tar -tzf "$file" 2>/dev/null | head -40
  local total
  total=$(tar -tzf "$file" 2>/dev/null | wc -l)
  [[ "$total" -gt 40 ]] && echo "  ... and $(($total - 40)) more files"
  echo
  log_info "Total: $total files"
}

backup_cron() {
  local cron_job="0 3 * * * ${KARNEL_BIN:-karnel} backup"
  if crontab -l 2>/dev/null | grep -q "karnel backup"; then
    log_info "Cron backup already configured"
    return 0
  fi
  (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
  log_success "Daily backup scheduled at 3:00 AM"
  echo "  Edit with: crontab -e"
}

backup_restore() {
  local file="${1:-}"
  if [[ -z "$file" ]]; then
    file=$(ls -t "$BACKUP_DIR"/termux-*.tar.gz 2>/dev/null | head -1)
    [[ -z "$file" ]] && log_error "No backups found to restore" && return 1
    log_info "Restoring latest backup: $(basename "$file")"
  else
    [[ "$file" != /* ]] && file="$BACKUP_DIR/$file"
    [[ ! -f "$file" ]] && log_error "Backup not found: $file" && return 1
  fi

  echo
  box "Restore"
  echo
  log_warn "This will overwrite your current configuration files!"
  echo "  Backup: $(basename "$file")"
  echo "  Size: $(du -h "$file" | awk '{print $1}')"
  echo "  Date: $(date -r "$file" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)"
  echo

  # Verify checksum
  local expected actual
  if [[ -f "$file.sha256" ]]; then
    expected=$(cat "$file.sha256")
    actual=$(sha256sum "$file" | awk '{print $1}')
    if [[ "$expected" != "$actual" ]]; then
      log_error "Checksum mismatch! Backup may be corrupted."
      log_info "Expected: $expected"
      log_info "Actual:   $actual"
      return 1
    fi
    log_success "Checksum verified"
  fi

  local tmp
  tmp=$(mktemp -d)
  tar -xzf "$file" -C "$tmp" 2>/dev/null
  log_success "Extracted backup"

  # Restore configs
  [[ -d "$tmp/config/home" ]] && cp -r "$tmp/config/home/." "$HOME/" 2>/dev/null
  [[ -d "$tmp/config/termux" ]] && cp -r "$tmp/config/termux/." "$HOME/.termux/" 2>/dev/null && termux-reload-settings 2>/dev/null || true
  [[ -d "$tmp/config/ssh" ]] && cp -r "$tmp/config/ssh/." "$HOME/.ssh/" 2>/dev/null && chmod 600 "$HOME/.ssh/id_"* 2>/dev/null
  for d in "$tmp/config/config"/*/; do
    [[ -d "$d" ]] && cp -r "$d" "$HOME/.config/" 2>/dev/null
  done
  [[ -f "$tmp/config/prefix-etc/sources.list" ]] && cp "$tmp/config/prefix-etc/sources.list" "$PREFIX/etc/apt/sources.list" 2>/dev/null

  # Restore env vars
  if [[ -f "$tmp/config/env/karnel.env" ]]; then
    local env_bak="$HOME/.karnel-env-backup"
    cp "$tmp/config/env/karnel.env" "$env_bak" 2>/dev/null
    log_info "Env vars saved to $env_bak — source it to restore: source $env_bak"
  fi

  rm -rf "$tmp"
  log_success "Restore complete! Restart your terminal."
  echo
}

_backup_cloud() {
  local file="$1"
  if ! command -v rclone &>/dev/null; then
    pkg install rclone -y &>/dev/null || log_warn "Install rclone: pkg install rclone"
  fi
  if command -v rclone &>/dev/null; then
    if rclone listremotes 2>/dev/null | grep -q "^karnel:"; then
      loading "Uploading" rclone copy "$file" "karnel:backups/"
      log_success "Uploaded to cloud"
    else
      log_warn "Run 'rclone config' and name the remote 'karnel'"
    fi
  fi
}
