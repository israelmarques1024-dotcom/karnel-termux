#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/backup"
import "@/tools/osint/robin/common"

BACKUP_DIR="${KARNEL_DATA}/backups"
mkdir -p "$BACKUP_DIR"

backup_main() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    --help|-h)      backup_help ;;
    list|ls)        backup_list ;;
    info|show)      backup_info "$@" ;;
    snapshot)       backup_snapshot "$@" ;;
    --cron)         backup_cron ;;
    --cloud)        backup_run true ;;
    restore)        import "@/cli/commands/restore"; restore_main "$@" ;;
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
  _backup_reserve_output "$BACKUP_DIR" "termux-$ts" ".tar.gz" || return 1
  local file="$BACKUP_RESERVED_FILE" lock="$BACKUP_RESERVED_LOCK"

  echo
  box "Karnel Backup"
  echo

  local tmp archive_tmp checksum_tmp
  tmp=$(mktemp -d) || { _backup_release_output; return 1; }
  archive_tmp="$BACKUP_DIR/.$(basename "$file").$$.tmp"
  checksum_tmp="$archive_tmp.sha256"
  if ! _backup_collect_payload "$tmp"; then
    rm -rf -- "$tmp" "$archive_tmp" "$checksum_tmp"
    rmdir -- "$lock" 2>/dev/null || true
    BACKUP_RESERVED_LOCK=""
    log_error "Failed to collect backup data"
    return 1
  fi
  local pkgs
  pkgs=$(wc -l <"$tmp/metadata/packages.list")
  log_success "Saved $pkgs installed packages"
  log_success "Saved $BACKUP_TOOL_COUNT catalog entries"

  if ! tar -czf "$archive_tmp" -C "$tmp" . 2>/dev/null; then
    rm -rf -- "$tmp" "$archive_tmp" "$checksum_tmp"
    rmdir -- "$lock" 2>/dev/null || true
    BACKUP_RESERVED_LOCK=""
    log_error "Failed to create backup archive"
    return 1
  fi
  rm -rf -- "$tmp"

  local size checksum
  checksum=$(sha256sum "$archive_tmp" 2>/dev/null) || { rm -f -- "$archive_tmp"; _backup_release_output; return 1; }
  checksum=${checksum%% *}
  if ! printf '%s  %s\n' "$checksum" "$(basename "$file")" >"$checksum_tmp" ||
     ! mv -- "$archive_tmp" "$file" || ! mv -- "$checksum_tmp" "$file.sha256"; then
    rm -f -- "$archive_tmp" "$checksum_tmp" "$file" "$file.sha256"
    _backup_release_output
    log_error "Failed to publish backup"
    return 1
  fi
  _backup_release_output
  size=$(du -h "$file" | awk '{print $1}')
  log_success "Backup: $(basename "$file") ($size)"
  log_success "Checksum (SHA256): ${checksum:0:16}...${checksum: -16}"

  if $cloud; then
    if [[ "${KARNEL_ALLOW_PLAINTEXT_CLOUD_BACKUP:-0}" != "1" ]]; then
      log_error "Cloud backup is disabled because archives are not encrypted or signed"
      log_info "Set KARNEL_ALLOW_PLAINTEXT_CLOUD_BACKUP=1 only if you accept this risk"
      return 1
    fi
    _backup_cloud "$file" "$file.sha256" || return 1
  fi

  echo
  log_success "Done! Restore with: karnel restore"
  echo
}

backup_snapshot() {
  local name="${1:-manual}"
  if [[ ! "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ || "$name" == "." || "$name" == ".." ]]; then
    log_error "Invalid snapshot name; use 1-64 letters, numbers, dots, underscores, or hyphens"
    return 1
  fi
  local ts
  ts=$(date +%Y%m%d_%H%M%S)
  _backup_reserve_output "$BACKUP_DIR" "snapshot-$name-$ts" ".tar.gz" || return 1
  local file="$BACKUP_RESERVED_FILE" lock="$BACKUP_RESERVED_LOCK"

  echo
  box "Karnel Snapshot: $name"
  echo

  local tmp archive_tmp checksum_tmp checksum
  tmp=$(mktemp -d) || { _backup_release_output; return 1; }
  archive_tmp="$BACKUP_DIR/.$(basename "$file").$$.tmp"
  checksum_tmp="$archive_tmp.sha256"
  if ! _backup_collect_payload "$tmp" ||
     ! printf '%s\n%s\n' "$ts" "$name" >"$tmp/metadata/snapshot" ||
     ! tar -czf "$archive_tmp" -C "$tmp" . 2>/dev/null; then
    rm -rf -- "$tmp" "$archive_tmp" "$checksum_tmp"
    rmdir -- "$lock" 2>/dev/null || true
    BACKUP_RESERVED_LOCK=""
    log_error "Failed to create snapshot"
    return 1
  fi
  rm -rf -- "$tmp"
  checksum=$(sha256sum "$archive_tmp" 2>/dev/null) || { rm -f -- "$archive_tmp"; _backup_release_output; return 1; }
  checksum=${checksum%% *}
  if ! printf '%s  %s\n' "$checksum" "$(basename "$file")" >"$checksum_tmp" ||
     ! mv -- "$archive_tmp" "$file" || ! mv -- "$checksum_tmp" "$file.sha256"; then
    rm -f -- "$archive_tmp" "$checksum_tmp" "$file" "$file.sha256"
    _backup_release_output
    log_error "Failed to publish snapshot"
    return 1
  fi
  _backup_release_output
  log_success "Snapshot '$name' saved ($(du -h "$file" | awk '{print $1}'))"
}

_backup_collect_payload() {
  local destination="$1" source base file module tool found
  local -a tools=() ssh_files=()
  mkdir -p "$destination/config"/{home,termux,ssh,config,prefix-etc} "$destination/metadata" || return 1
  dpkg --get-selections >"$destination/metadata/packages.list" 2>/dev/null || return 1

  for source in \
    "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.zshenv" "$HOME/.inputrc" \
    "$HOME/.termux" "$HOME/.ssh" "$HOME/.config" "$PREFIX/etc/apt/sources.list"; do
    _backup_path_components_safe "$source" || return 1
  done

  for module in "$KARNEL_PATH/tools/"*/; do
    [[ -d "$module" ]] || continue
    for tool in "$module"*/; do
      [[ -d "$tool" ]] || continue
      found=false
      for file in "$tool"/*.sh; do [[ -f "$file" ]] && found=true && break; done
      $found && tools+=("$(basename "${module%/}"):$(basename "${tool%/}")")
    done
  done
  printf '%s\n' "${tools[@]}" >"$destination/metadata/tool-catalog.list" || return 1
  BACKUP_TOOL_COUNT=${#tools[@]}

  for file in .bashrc .zshrc .profile .zshenv .inputrc; do
    [[ ! -f "$HOME/$file" ]] || {
      _backup_path_components_safe "$HOME/$file" &&
        cp -a -- "$HOME/$file" "$destination/config/home/"
    } || return 1
  done
  if [[ -d "$HOME/.termux" ]]; then
    _backup_path_components_safe "$HOME/.termux" || return 1
    cp -a -- "$HOME/.termux/." "$destination/config/termux/" || return 1
  fi
  if [[ -d "$HOME/.ssh" ]]; then
    for source in "$HOME/.ssh"/*.pub "$HOME/.ssh/config" "$HOME/.ssh/known_hosts" "$HOME/.ssh/authorized_keys"; do
      [[ -e "$source" || -L "$source" ]] || continue
      _backup_path_components_safe "$source" || return 1
      [[ -f "$source" ]] && ssh_files+=("$source")
    done
    if ((${#ssh_files[@]} > 0)); then
      for source in "${ssh_files[@]}"; do
        _backup_path_components_safe "$source" || return 1
      done
      cp -a -- "${ssh_files[@]}" "$destination/config/ssh/" || return 1
    fi
  fi

  for source in "$HOME/.config"/*; do
    [[ -e "$source" || -L "$source" ]] || continue
    _backup_path_components_safe "$source" || return 1
    [[ -d "$source" ]] || continue
    base=$(basename "$source")
    case "$base" in github-copilot|nvm|coc|Code|yarn) continue ;; esac
    cp -a -- "$source" "$destination/config/config/" || return 1
  done
  find "$destination/config/config" -type f \( -name '.env' -o -name '.env.*' -o \
    -name 'credentials' -o -name 'credentials.*' -o -name 'auth.json' -o \
    -name 'token' -o -name 'token.*' -o -name 'tokens.json' \) -delete || return 1
  # Do not follow or archive links that could expose files outside the selected trees.
  find "$destination/config" -type l -delete || return 1
  if [[ -f "$PREFIX/etc/apt/sources.list" ]]; then
    _backup_path_components_safe "$PREFIX/etc/apt/sources.list" || return 1
    cp -a -- "$PREFIX/etc/apt/sources.list" "$destination/config/prefix-etc/" || return 1
  fi
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
    file=$(_backup_latest "$BACKUP_DIR" 'termux-*.tar.gz')
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
  [[ "$total" -gt 40 ]] && echo "  ... and $((total - 40)) more files"
  echo
  log_info "Total: $total files"
}

backup_cron() {
  local configured="${KARNEL_BIN:-$KARNEL_PATH/bin/karnel}" executable quoted cron_job current line
  executable="$configured"
  [[ -d "$executable" ]] && executable="$executable/karnel"
  [[ -f "$executable" ]] || { log_error "Karnel executable not found: $executable"; return 1; }
  printf -v quoted '%q' "$executable"
  cron_job="0 3 * * * $quoted backup"
  current=$(crontab -l 2>/dev/null || true)
  if printf '%s\n' "$current" | grep -Fqx "$cron_job"; then
    log_info "Cron backup already configured"
    return 0
  fi
  (
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      [[ "$line" == *"karnel backup"* || "$line" == *"$configured backup"* ]] && continue
      printf '%s\n' "$line"
    done <<<"$current"
    printf '%s\n' "$cron_job"
  ) | crontab - || {
    log_error "Failed to install cron entry"
    return 1
  }
  log_success "Daily backup scheduled at 3:00 AM"
  echo "  Edit with: crontab -e"
}

_backup_cloud() {
  local -a files=("$@")
  if ! command -v rclone &>/dev/null; then
    pkg install rclone -y &>/dev/null || log_warn "Install rclone: pkg install rclone"
  fi
  if command -v rclone &>/dev/null; then
    if rclone listremotes 2>/dev/null | grep -q "^karnel:"; then
      local file
      for file in "${files[@]}"; do
        loading "Uploading $(basename "$file")" rclone copy "$file" "karnel:backups/" || return 1
      done
      log_success "Uploaded archive and checksum to cloud"
    else
      log_warn "Run 'rclone config' and name the remote 'karnel'"
      return 1
    fi
  else
    return 1
  fi
}
