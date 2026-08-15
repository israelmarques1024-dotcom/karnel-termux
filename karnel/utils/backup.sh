#!/usr/bin/env bash

_backup_verify_checksum() {
  local file="$1" checksum_file="$1.sha256" expected actual
  [[ -f "$checksum_file" ]] || return 1
  read -r expected _ <"$checksum_file" || return 1
  [[ "$expected" =~ ^[[:xdigit:]]{64}$ ]] || return 1
  actual=$(sha256sum "$file" 2>/dev/null) || return 1
  actual=${actual%% *}
  [[ "$actual" == "$expected" ]]
}

_backup_latest() {
  local directory="$1" pattern="$2" latest="" file
  for file in "$directory"/$pattern; do
    [[ -f "$file" ]] || continue
    [[ -z "$latest" || "$file" -nt "$latest" ]] && latest="$file"
  done
  [[ -n "$latest" ]] || return 1
  printf '%s\n' "$latest"
}

_backup_reserve_output() {
  local directory="$1" stem="$2" suffix="$3" candidate lock sequence=0
  while :; do
    candidate="$stem"
    ((sequence > 0)) && candidate="${stem}-${sequence}"
    lock="$directory/.${candidate}${suffix}.lock"
    if [[ -e "$directory/${candidate}${suffix}" || -e "$directory/${candidate}${suffix}.sha256" ]]; then
      ((sequence++))
      continue
    fi
    if mkdir "$lock" 2>/dev/null; then
      if [[ -e "$directory/${candidate}${suffix}" || -e "$directory/${candidate}${suffix}.sha256" ]]; then
        rmdir -- "$lock" 2>/dev/null || true
        ((sequence++))
        continue
      fi
      # shellcheck disable=SC2034 # consumed by callers after this reservation helper returns
      BACKUP_RESERVED_FILE="$directory/${candidate}${suffix}"
      BACKUP_RESERVED_LOCK="$lock"
      return 0
    fi
    ((sequence++))
  done
}

_backup_release_output() {
  [[ -n "${BACKUP_RESERVED_LOCK:-}" ]] && rmdir -- "$BACKUP_RESERVED_LOCK" 2>/dev/null || true
  BACKUP_RESERVED_LOCK=""
}

_backup_archive_safe() {
  local file="$1" listing member verbose mode
  listing=$(tar -tzf "$file" 2>/dev/null) || return 1
  while IFS= read -r member; do
    [[ -n "$member" ]] || continue
    [[ "$member" != /* && ! "$member" =~ (^|/)\.\.(/|$) ]] || return 1
  done <<<"$listing"

  verbose=$(tar -tvzf "$file" 2>/dev/null) || return 1
  while IFS= read -r mode _; do
    case "${mode:0:1}" in
      l|h|b|c|p) return 1 ;;
    esac
  done <<<"$verbose"
}

_backup_path_components_safe() {
  local path="$1"
  [[ "$path" == /* ]] || return 1
  path=${path%/}
  [[ -n "$path" ]] || path=/
  while :; do
    [[ ! -L "$path" ]] || return 1
    [[ "$path" == / ]] && return 0
    path=${path%/*}
    [[ -n "$path" ]] || path=/
  done
}

_backup_restore_destinations_safe() {
  local destination
  for destination in "${_BACKUP_RESTORE_DESTINATIONS[@]}"; do
    _backup_path_components_safe "$destination" || return 1
  done
}

_backup_restore_reset() {
  _BACKUP_RESTORE_DESTINATIONS=()
  _BACKUP_RESTORE_STAGED=()
  _BACKUP_RESTORE_BACKUPS=()
  _BACKUP_RESTORE_EXISTED=()
  _BACKUP_RESTORE_COMMITTED=0
  _BACKUP_RESTORE_ROLLBACK_FAILED=0
}

_backup_restore_prepare() {
  local source="$1" destination="$2" transaction="$3"
  local index=${#_BACKUP_RESTORE_DESTINATIONS[@]}
  local staged="$transaction/staged/$index" saved="$transaction/original/$index"

  [[ -n "$source" && -n "$destination" && "$destination" == /* ]] || return 1
  [[ -e "$source" ]] || return 1
  _backup_path_components_safe "$source" || return 1
  _backup_path_components_safe "$destination" || return 1
  mkdir -p "$transaction/staged" "$transaction/original" || return 1

  if [[ -d "$source" ]]; then
    [[ ! -e "$destination" || -d "$destination" ]] || return 1
    mkdir -p "$staged" || return 1
    if [[ -d "$destination" ]]; then
      _backup_path_components_safe "$destination" || return 1
      cp -a "$destination/." "$staged/" || return 1
    fi
    _backup_path_components_safe "$source" || return 1
    cp -a "$source/." "$staged/" || return 1
  else
    [[ -f "$source" ]] || return 1
    _backup_path_components_safe "$source" || return 1
    cp -a "$source" "$staged" || return 1
  fi

  _BACKUP_RESTORE_DESTINATIONS+=("$destination")
  _BACKUP_RESTORE_STAGED+=("$staged")
  _BACKUP_RESTORE_BACKUPS+=("$saved")
  if [[ -e "$destination" ]]; then
    _BACKUP_RESTORE_EXISTED+=(1)
  else
    _BACKUP_RESTORE_EXISTED+=(0)
  fi
}

_backup_restore_rollback() {
  local index destination saved failed=0
  for ((index = _BACKUP_RESTORE_COMMITTED - 1; index >= 0; index--)); do
    destination=${_BACKUP_RESTORE_DESTINATIONS[index]}
    saved=${_BACKUP_RESTORE_BACKUPS[index]}
    if ! _backup_path_components_safe "$destination"; then
      failed=1
      continue
    fi
    if [[ ${_BACKUP_RESTORE_EXISTED[index]} == 1 ]]; then
      if [[ -e "$saved" ]]; then
        rm -rf -- "$destination" && mv -- "$saved" "$destination" || failed=1
      elif [[ ! -e "$destination" ]]; then
        failed=1
      fi
    elif ! rm -rf -- "$destination"; then
      failed=1
    fi
  done
  _BACKUP_RESTORE_COMMITTED=0
  _BACKUP_RESTORE_ROLLBACK_FAILED=$failed
  ((failed == 0))
}

_backup_restore_commit() {
  local index destination staged saved
  _backup_restore_destinations_safe || return 1
  for ((index = 0; index < ${#_BACKUP_RESTORE_DESTINATIONS[@]}; index++)); do
    destination=${_BACKUP_RESTORE_DESTINATIONS[index]}
    staged=${_BACKUP_RESTORE_STAGED[index]}
    saved=${_BACKUP_RESTORE_BACKUPS[index]}
    _backup_path_components_safe "$destination" || { _backup_restore_rollback || true; return 1; }
    mkdir -p "$(dirname "$destination")" || { _backup_restore_rollback || true; return 1; }
    _backup_path_components_safe "$destination" || { _backup_restore_rollback || true; return 1; }
    _BACKUP_RESTORE_COMMITTED=$((index + 1))
    if [[ ${_BACKUP_RESTORE_EXISTED[index]} == 1 ]]; then
      if ! mv -- "$destination" "$saved"; then
        _BACKUP_RESTORE_COMMITTED=$index
        _backup_restore_rollback || true
        return 1
      fi
    fi
    _backup_path_components_safe "$destination" || { _backup_restore_rollback || true; return 1; }
    if ! mv -- "$staged" "$destination"; then
      _backup_restore_rollback || true
      return 1
    fi
  done
}
