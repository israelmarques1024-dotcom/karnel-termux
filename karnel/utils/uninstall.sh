#!/usr/bin/env bash

confirm_remove_paths() {
  local label="$1"
  shift
  local default="${KARNEL_REMOVE_DEFAULT:-n}"
  local answer path
  local -a existing=()

  for path in "$@"; do
    [[ -e "$path" || -L "$path" ]] || continue
    # Ownership gate: refuse to remove a path that is not managed by Karnel unless
    # explicitly forced. This prevents silently deleting a user's own directory
    # (e.g. a pre-existing ~/.oh-my-zsh or ~/.zsh-plugins/<plugin>).
    if [[ -z "${KARNEL_FORCE:-}" ]]; then
      local owned=0
      for marker in "$path/.karnel-managed" "$path/.karnel-pinned-git" "$path/.managed-by-karnel"; do
        [[ -f "$marker" ]] && owned=1 && break
      done
      if (( owned == 0 )); then
        log_warn "Preserving $label at $path (not managed by Karnel)"
        continue
      fi
    fi
    existing+=("$path")
  done
  (( ${#existing[@]} > 0 )) || return 2

  read_confirm_default "Remove $label configuration and data?" "$default" answer || return 2
  [[ "$answer" == "y" ]] || return 2

  rm -rf -- "${existing[@]}"
}

remove_marked_block() {
  local file="$1" begin="$2" end="$3" start_line end_line

  start_line="$(grep -nF "$begin" "$file" 2>/dev/null | head -1 | cut -d: -f1)"
  end_line="$(grep -nF "$end" "$file" 2>/dev/null | head -1 | cut -d: -f1)"
  [[ -n "$start_line" && -n "$end_line" && "$end_line" -ge "$start_line" ]] || return 2

  sed -i "${start_line},${end_line}d" "$file"
}
