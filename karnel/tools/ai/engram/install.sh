#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/version"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
ENGRAM_REPO="https://github.com/Gentleman-Programming/engram.git"
ENGRAM_COMMIT="1dafc0f63051b2214100f7bd801357e4aab61c26"
ENGRAM_DATA_DIR="$KARNEL_DATA/engram"
ENGRAM_MARKER="$ENGRAM_DATA_DIR/.karnel-managed"
ENGRAM_WRAPPER_MARKER="$ENGRAM_DATA_DIR/.karnel-wrapper"

_engram_data_owned() {
  [ -f "$ENGRAM_MARKER" ]
}

_engram_bin_owned() {
  managed_file_matches "$PREFIX/bin/engram" "$ENGRAM_WRAPPER_MARKER"
}

_engram_verify_ownership() {
  if [ -e "$PREFIX/bin/engram" ] && ! _engram_bin_owned; then
    log_error "Refusing to replace unowned command: $PREFIX/bin/engram"
    return 1
  fi
  if [ -d "$ENGRAM_DATA_DIR" ] && ! _engram_data_owned; then
    log_error "Refusing to replace Engram data not owned by Karnel: $ENGRAM_DATA_DIR"
    return 1
  fi
}

_engram_dependencies() {
  loading "Installing dependencies" _engram_dependencies_impl
}

_engram_dependencies_impl() {
  declare -A DEPS=(
    ["golang"]="go"
    ["git"]="git"
    ["sqlite"]="sqlite3"
  )

  local pkg_name bin_name
  for pkg_name in "${!DEPS[@]}"; do
    bin_name="${DEPS[$pkg_name]}"
    if ! command -v "$bin_name" &>/dev/null; then
      if ! pkg install "$pkg_name" -y &>>"$LOG_FILE"; then
        log_error "Failed to install $pkg_name"
        return 1
      fi
    fi
  done

  return 0
}

_clone_engram_repo() {
  loading "Cloning engram repository" _clone_engram_repo_impl
}

_clone_engram_repo_impl() {
  if ! install_pinned_git_repo "$ENGRAM_REPO" "$ENGRAM_COMMIT" "$ENGRAM_DATA_DIR"; then
    log_error "Failed to clone engram repository"
    return 1
  fi
  printf '%s\n' 'karnel-managed-v1' >"$ENGRAM_MARKER"

  return 0
}

_build_engram() {
  loading "Building engram binary" _build_engram_impl
}

_build_engram_impl() {
  _engram_verify_ownership || return 1
  if ! go build -C "$ENGRAM_DATA_DIR/cmd/engram" -o "$PREFIX/bin/engram" &>>"$LOG_FILE"; then
    log_error "Failed to build engram"
    return 1
  fi
  record_managed_file "$PREFIX/bin/engram" "$ENGRAM_WRAPPER_MARKER"

  return 0
}

install_engram() {
  if command -v engram &>/dev/null && _engram_bin_owned; then
    log_info "Engram is already installed"
    return 2
  fi
  _engram_verify_ownership || return 1
  log_info "Installing Engram..."

  export GOPATH="$HOME/.local/go"
  export GOCACHE="$HOME/.cache/go"
  export GOMODCACHE="$GOPATH/pkg/mod"

  mkdir -p "$(dirname "$LOG_FILE")"

  _engram_dependencies || return 1
  _clone_engram_repo || return 1
  _build_engram || return 1

  log_success "Engram installed"
  return 0
}

uninstall_engram() {
  if ! command -v engram &>/dev/null && [ ! -d "$ENGRAM_DATA_DIR" ]; then
    log_info "Engram is not installed"
    return 2
  fi
  if [ -e "$PREFIX/bin/engram" ] && ! _engram_bin_owned; then
    log_error "Refusing to remove unowned command: $PREFIX/bin/engram"
    return 1
  fi
  if [ -d "$ENGRAM_DATA_DIR" ] && ! _engram_data_owned; then
    log_error "Refusing to remove Engram data not owned by Karnel: $ENGRAM_DATA_DIR"
    return 1
  fi
  log_info "Uninstalling Engram..."
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Removing Engram" _uninstall_engram_impl || return 1

  log_success "Engram uninstalled"
  return 0
}

_uninstall_engram_impl() {
  if [[ -n "$ENGRAM_DATA_DIR" && -d "$ENGRAM_DATA_DIR" ]] && _engram_data_owned; then
    rm -rf "$ENGRAM_DATA_DIR"
  fi
  if _engram_bin_owned; then
    rm -f "$PREFIX/bin/engram" &>>"$LOG_FILE"
  fi
  return 0
}

update_engram() {
  _update_engram_impl
}

_update_engram_impl() {
	export GOPATH="$HOME/.local/go"
	export GOCACHE="$HOME/.cache/go"
	export GOMODCACHE="$GOPATH/pkg/mod"

	if ! install_pinned_git_repo "$ENGRAM_REPO" "$ENGRAM_COMMIT" "$ENGRAM_DATA_DIR"; then
		log_error "Failed to install pinned engram repository"
		return 1
	fi
	printf '%s\n' 'karnel-managed-v1' >"$ENGRAM_MARKER"
	if ! go build -C "$ENGRAM_DATA_DIR/cmd/engram" -o "$PREFIX/bin/engram" &>>"$LOG_FILE"; then
		log_error "Failed to build Engram"
		return 1
	fi
	record_managed_file "$PREFIX/bin/engram" "$ENGRAM_WRAPPER_MARKER"
	return 0
}

reinstall_engram() {
  uninstall_engram
  install_engram
}
