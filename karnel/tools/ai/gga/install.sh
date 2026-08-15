#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/install"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
GGA_DATA_DIR="$KARNEL_DATA/gga-termux"
GGA_RUNTIME_DIR="$KARNEL_DATA/gga-runtime"
GGA_REPO="https://github.com/Gentleman-Programming/gentleman-guardian-angel.git"
GGA_COMMIT="1124c3672f082c56b033c4e23a30e95d0e8cd593"
GGA_VERSION="2.10.1"

_gga_runtime_owned() {
  [[ -d "$GGA_RUNTIME_DIR" && ! -L "$GGA_RUNTIME_DIR" &&
    -f "$GGA_RUNTIME_DIR/.karnel-managed" &&
    "$(<"$GGA_RUNTIME_DIR/.karnel-managed")" == "karnel-gga-v1" ]]
}

_gga_command_owned() {
  local marker="$GGA_RUNTIME_DIR/.karnel-command-sha256"
  _gga_runtime_owned && [[ -f "$PREFIX/bin/gga" && ! -L "$PREFIX/bin/gga" && -f "$marker" ]] &&
    [[ "$(sha256sum "$PREFIX/bin/gga" 2>/dev/null | cut -d' ' -f1)" == "$(<"$marker")" ]]
}

_gga_verify_ownership() {
  if [[ -e "$GGA_DATA_DIR" || -L "$GGA_DATA_DIR" ]]; then
    if ! _pinned_git_repo_owned "$GGA_DATA_DIR" "$GGA_REPO"; then
      log_error "Refusing to replace unowned GGA source: $GGA_DATA_DIR"
      return 1
    fi
  fi
  if [[ -e "$GGA_RUNTIME_DIR" || -L "$GGA_RUNTIME_DIR" ]]; then
    if ! _gga_runtime_owned; then
      log_error "Refusing to replace unowned GGA runtime: $GGA_RUNTIME_DIR"
      return 1
    fi
  fi
  if [[ -e "$PREFIX/bin/gga" || -L "$PREFIX/bin/gga" ]]; then
    if ! _gga_command_owned; then
      log_error "Refusing to replace unowned command: $PREFIX/bin/gga"
      return 1
    fi
  fi
}

_gga_dependencies() {
  loading "Installing dependencies" _gga_dependencies_impl
}

_gga_dependencies_impl() {
  # shellcheck disable=SC2034 # Read through install_deps' nameref.
  declare -A DEPS=(
    ["git"]="git"
    ["curl"]="curl"
  )
  install_deps DEPS
}

_gga_fetch_source() {
  loading "Fetching pinned GGA source" _gga_fetch_source_impl
}

_gga_fetch_source_impl() {
  install_pinned_git_repo "$GGA_REPO" "$GGA_COMMIT" "$GGA_DATA_DIR"
}

_gga_deploy() {
  loading "Installing GGA" _gga_deploy_impl
}

_gga_deploy_impl() {
  local runtime_stage command_stage runtime_backup command_backup
  runtime_stage=$(mktemp -d "$KARNEL_DATA/.gga-runtime-stage.XXXXXX") || return 1
  command_stage=$(mktemp "$PREFIX/bin/.gga-stage.XXXXXX") || {
    rm -rf "$runtime_stage"
    return 1
  }
  runtime_backup="$KARNEL_DATA/.gga-runtime-backup.$$"
  command_backup="$PREFIX/bin/.gga-backup.$$"

  if ! cp "$GGA_DATA_DIR/bin/gga" "$command_stage" ||
    ! mkdir -p "$runtime_stage/lib" ||
    ! cp "$GGA_DATA_DIR/lib/providers.sh" "$GGA_DATA_DIR/lib/cache.sh" \
      "$GGA_DATA_DIR/lib/pr_mode.sh" "$runtime_stage/lib/"; then
    rm -rf "$runtime_stage" "$command_stage"
    log_error "Failed to stage GGA files"
    return 1
  fi
  sed -i "1s|^#!.*|#!$PREFIX/bin/bash|" "$command_stage" || {
    rm -rf "$runtime_stage" "$command_stage"
    return 1
  }
  sed -i "s|^VERSION=.*|VERSION=\"$GGA_VERSION\"|" "$command_stage" || {
    rm -rf "$runtime_stage" "$command_stage"
    return 1
  }
  sed -i "s|^LIB_DIR=.*|LIB_DIR=\"$GGA_RUNTIME_DIR/lib\"|" "$command_stage" || {
    rm -rf "$runtime_stage" "$command_stage"
    return 1
  }
  chmod 0755 "$command_stage" "$runtime_stage/lib/"*.sh
  printf '%s\n' 'karnel-gga-v1' >"$runtime_stage/.karnel-managed"
  sha256sum "$command_stage" | cut -d' ' -f1 >"$runtime_stage/.karnel-command-sha256"

  [[ ! -e "$runtime_backup" && ! -L "$runtime_backup" &&
    ! -e "$command_backup" && ! -L "$command_backup" ]] || {
    rm -rf "$runtime_stage" "$command_stage"
    log_error "Temporary GGA backup path already exists"
    return 1
  }
  if [[ -e "$GGA_RUNTIME_DIR" ]]; then
    mv "$GGA_RUNTIME_DIR" "$runtime_backup" || return 1
  fi
  if [[ -e "$PREFIX/bin/gga" ]]; then
    if ! mv "$PREFIX/bin/gga" "$command_backup"; then
      [[ ! -e "$runtime_backup" ]] || mv "$runtime_backup" "$GGA_RUNTIME_DIR"
      rm -rf "$runtime_stage" "$command_stage"
      return 1
    fi
  fi
  if ! mv "$runtime_stage" "$GGA_RUNTIME_DIR" || ! mv "$command_stage" "$PREFIX/bin/gga"; then
    rm -rf "$GGA_RUNTIME_DIR" "$PREFIX/bin/gga" "$runtime_stage" "$command_stage"
    [[ ! -e "$runtime_backup" ]] || mv "$runtime_backup" "$GGA_RUNTIME_DIR"
    [[ ! -e "$command_backup" ]] || mv "$command_backup" "$PREFIX/bin/gga"
    log_error "Failed to activate GGA"
    return 1
  fi
  rm -rf "$runtime_backup" "$command_backup"
}

install_gga() {
  if command -v gga &>/dev/null; then
    log_info "GGA is already installed"
    return 2
  fi

  log_info "Installing GGA..."
  mkdir -p "$(dirname "$LOG_FILE")" "$KARNEL_DATA" "$PREFIX/bin"
  _gga_verify_ownership || return 1
  _gga_dependencies || return 1
  _gga_fetch_source || return 1
  _gga_deploy || return 1

  log_success "GGA installed"
}

uninstall_gga() {
  if [[ ! -e "$PREFIX/bin/gga" && ! -L "$PREFIX/bin/gga" &&
    ! -e "$GGA_RUNTIME_DIR" && ! -L "$GGA_RUNTIME_DIR" &&
    ! -e "$GGA_DATA_DIR" && ! -L "$GGA_DATA_DIR" ]]; then
    log_info "GGA is not installed"
    return 2
  fi
  _gga_verify_ownership || return 1

  log_info "Uninstalling GGA..."
  rm -f "$PREFIX/bin/gga"
  rm -rf "$GGA_RUNTIME_DIR" "$GGA_DATA_DIR"
  log_success "GGA uninstalled"
}

update_gga() {
  if ! _gga_command_owned; then
    log_error "Refusing to update an unowned or incomplete GGA installation"
    return 1
  fi
  _gga_verify_ownership || return 1
  _gga_fetch_source || return 1
  _gga_deploy
}

reinstall_gga() {
  local uninstall_rc=0
  uninstall_gga || uninstall_rc=$?
  [[ "$uninstall_rc" -eq 0 || "$uninstall_rc" -eq 2 ]] || return "$uninstall_rc"
  install_gga
}
