#!/usr/bin/env bash

_downloaded_python_owned() {
  local bin_name="$1" tool_dir="$2" payload="$2/$1.py" marker expected actual
  marker="$tool_dir/.karnel-installed"
  [[ -L "$PREFIX/bin/$bin_name" && "$(readlink "$PREFIX/bin/$bin_name")" == "$payload" && -f "$marker" ]] || return 1
  read -r expected _ <"$marker" || return 1
  read -r actual _ < <(sha256sum "$payload" 2>/dev/null) || return 1
  [[ -n "$expected" && "$actual" == "$expected" ]]
}

_downloaded_python_install() {
  local bin_name="$1" tool_dir="$2" download_url="$3" force_update="${4:-}"
  local payload="$tool_dir/$bin_name.py" marker python3_path source_payload
  local tool_staging link_staging staged_payload staged_marker staged_link
  local old_payload=0 old_marker=0 old_link=0 new_payload=0 new_marker=0 new_link=0 commit_failed=0 rollback_failed=0
  marker="$tool_dir/.karnel-installed"

  if [[ "$force_update" != force ]] && _downloaded_python_owned "$bin_name" "$tool_dir"; then
    log_info "$bin_name is already installed"
    return 2
  fi
  if [[ -e "$PREFIX/bin/$bin_name" || -L "$PREFIX/bin/$bin_name" || -e "$payload" ]] && ! _downloaded_python_owned "$bin_name" "$tool_dir"; then
    log_error "$bin_name is already owned by another installation"
    return 1
  fi
  mkdir -p "$tool_dir" "$PREFIX/bin" || return 1
  python3_path=$(command -v python3) || return 1

  tool_staging=$(mktemp -d "$tool_dir/.install.XXXXXX") || return 1
  link_staging=$(mktemp -d "$PREFIX/bin/.${bin_name}.install.XXXXXX") || { rmdir "$tool_staging"; return 1; }
  staged_payload="$tool_staging/$bin_name.py"
  staged_marker="$tool_staging/marker"
  staged_link="$link_staging/$bin_name"
  source_payload="${KARNEL_PATH:-}/tools/${tool_dir#"$KARNEL_DATA"/}/$bin_name.py"

  if [[ -n "${KARNEL_PATH:-}" && -f "$source_payload" ]]; then
    cp "$source_payload" "$staged_payload" || commit_failed=1
  else
    curl -fsSL "$download_url" -o "$staged_payload" || commit_failed=1
  fi
  if (( commit_failed != 0 )) || ! sed -i "1s|.*|#!$python3_path|" "$staged_payload" ||
    ! chmod 755 "$staged_payload" || ! sha256sum "$staged_payload" >"$staged_marker" ||
    ! ln -s "$payload" "$staged_link"; then
    rm -rf "$tool_staging" "$link_staging"
    return 1
  fi

  if [[ -e "$payload" ]]; then
    if mv "$payload" "$tool_staging/old.payload"; then old_payload=1; else commit_failed=1; fi
  fi
  if (( commit_failed == 0 )) && [[ -e "$marker" ]]; then
    if mv "$marker" "$tool_staging/old.marker"; then old_marker=1; else commit_failed=1; fi
  fi
  if (( commit_failed == 0 )) && [[ -e "$PREFIX/bin/$bin_name" || -L "$PREFIX/bin/$bin_name" ]]; then
    if mv "$PREFIX/bin/$bin_name" "$link_staging/old.link"; then old_link=1; else commit_failed=1; fi
  fi
  if (( commit_failed == 0 )); then if mv "$staged_payload" "$payload"; then new_payload=1; else commit_failed=1; fi; fi
  if (( commit_failed == 0 )); then if mv "$staged_marker" "$marker"; then new_marker=1; else commit_failed=1; fi; fi
  if (( commit_failed == 0 )); then if mv "$staged_link" "$PREFIX/bin/$bin_name"; then new_link=1; else commit_failed=1; fi; fi

  if (( commit_failed != 0 )); then
    (( new_payload == 0 )) || rm -f "$payload"
    (( new_marker == 0 )) || rm -f "$marker"
    (( new_link == 0 )) || rm -f "$PREFIX/bin/$bin_name"
    (( old_payload == 0 )) || mv "$tool_staging/old.payload" "$payload" || rollback_failed=1
    (( old_marker == 0 )) || mv "$tool_staging/old.marker" "$marker" || rollback_failed=1
    (( old_link == 0 )) || mv "$link_staging/old.link" "$PREFIX/bin/$bin_name" || rollback_failed=1
    (( rollback_failed != 0 )) || rm -rf "$tool_staging" "$link_staging"
    return 1
  fi
  rm -rf "$tool_staging" "$link_staging" || return 1
}

_downloaded_python_uninstall() {
  local bin_name="$1" tool_dir="$2" payload="$2/$1.py" marker
  marker="$tool_dir/.karnel-installed"
  if ! _downloaded_python_owned "$bin_name" "$tool_dir"; then
    log_info "$bin_name is not installed by Karnel"
    return 2
  fi
  rm -f "$PREFIX/bin/$bin_name" "$payload" "$marker" || return 1
  rmdir "$tool_dir" 2>/dev/null || true
}

_downloaded_python_update() {
  _downloaded_python_owned "$1" "$2" || { log_error "$1 is not installed by Karnel"; return 1; }
  _downloaded_python_install "$1" "$2" "$3" force
}
