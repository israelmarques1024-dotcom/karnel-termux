#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
KILOCODE_DATA_DIR="${KARNEL_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data}/kilocode"

_kilocode_wrapper_owned() {
  local marker="$KILOCODE_DATA_DIR/.karnel-wrapper-kilocode"
  [[ -f "$marker" && -f "$PREFIX/bin/kilocode" ]] || return 1
  [[ "$(sha256sum "$PREFIX/bin/kilocode" 2>/dev/null)" == "$(<"$marker")" ]]
}

_kilocode_alias_owned() {
  [[ -L "$PREFIX/bin/kilo" && "$(readlink "$PREFIX/bin/kilo")" == "$PREFIX/bin/kilocode" ]]
}

_kilocode_data_owned() {
  [[ -f "$KILOCODE_DATA_DIR/.karnel-managed" ]]
}

_kilocode_verify_ownership() {
  if [[ -e "$KILOCODE_DATA_DIR" ]] && ! _kilocode_data_owned; then
    log_error "Refusing to replace unowned Kilo Code data: $KILOCODE_DATA_DIR"
    return 1
  fi
  if [[ -e "$PREFIX/bin/kilocode" ]] && ! _kilocode_wrapper_owned; then
    log_error "Refusing to replace unowned command: $PREFIX/bin/kilocode"
    return 1
  fi
  if [[ -e "$PREFIX/bin/kilo" || -L "$PREFIX/bin/kilo" ]] && ! _kilocode_alias_owned; then
    log_error "Refusing to replace unowned command: $PREFIX/bin/kilo"
    return 1
  fi
}

_get_latest_kilocode_version() {
  curl -fsSL https://api.github.com/repos/Kilo-Org/kilocode/releases/latest |
    grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

_install_kilocode_deps() {
  loading "Installing glibc and dependencies" _install_kilocode_deps_impl
}

_install_kilocode_deps_impl() {
  if [[ ! -f $PREFIX/etc/apt/sources.list.d/glibc.list ]]; then
    if ! yes | pkg install glibc-repo &>>"$LOG_FILE"; then
      log_error "Failed to install glibc-repo"
      return 1
    fi
  fi

  if [[ ! -f $PREFIX/glibc/lib/libc.so.6 ]]; then
    if ! yes | pkg install glibc &>>"$LOG_FILE"; then
      log_error "Failed to install glibc"
      return 1
    fi
  fi

  declare -A DEPS=(
    ["git"]="git"
    ["ripgrep"]="rg"
    ["python"]="python"
    ["clang"]="cc"
    ["jq"]="jq"
    ["nodejs-lts"]="node"
    ["curl"]="curl"
    ["tar"]="tar"
  )

  local pkg_name bin_name
  for pkg_name in "${!DEPS[@]}"; do
    bin_name="${DEPS[$pkg_name]}"
    if ! command -v "$bin_name" &>/dev/null; then
      if ! yes | pkg install "$pkg_name" &>>"$LOG_FILE"; then
        log_error "Failed to install $pkg_name"
        return 1
      fi
    fi
  done

  return 0
}

_download_kilocode_binary() {
  loading "Downloading Kilo Code CLI" _download_kilocode_binary_impl
}

_download_kilocode_binary_impl() {
  local latest_version
  latest_version=$(_get_latest_kilocode_version)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Kilo Code CLI version"
    return 1
  fi

  mkdir -p "$(dirname "$KILOCODE_DATA_DIR")" || return 1

  local staging_dir
  staging_dir="$(mktemp -d "$(dirname "$KILOCODE_DATA_DIR")/.kilocode.XXXXXX")" || return 1

  local tarball="kilo-linux-arm64.tar.gz"
  local download_url="https://github.com/Kilo-Org/kilocode/releases/download/$latest_version/$tarball"

  if ! curl -fsSL "$download_url" -o "$staging_dir/$tarball" &>>"$LOG_FILE"; then
    rm -rf "$staging_dir"
    log_error "Failed to download Kilo Code CLI binary"
    return 1
  fi

  if ! tar -zxf "$staging_dir/$tarball" -C "$staging_dir" &>>"$LOG_FILE"; then
    rm -rf "$staging_dir"
    log_error "Failed to extract Kilo Code CLI binary"
    return 1
  fi

  rm -f "$staging_dir/$tarball"

  if [ ! -f "$staging_dir/kilo" ]; then
    rm -rf "$staging_dir"
    log_error "Kilo Code CLI binary not found after extraction"
    return 1
  fi

  chmod +x "$staging_dir/kilo"

  local old_dir="${KILOCODE_DATA_DIR}.previous.$$"
  if [[ -e "$KILOCODE_DATA_DIR" ]] && ! mv "$KILOCODE_DATA_DIR" "$old_dir"; then
    rm -rf "$staging_dir"
    return 1
  fi
  if ! mv "$staging_dir" "$KILOCODE_DATA_DIR"; then
    [[ -e "$old_dir" ]] && mv "$old_dir" "$KILOCODE_DATA_DIR"
    rm -rf "$staging_dir"
    return 1
  fi
  rm -rf "$old_dir"
  : >"$KILOCODE_DATA_DIR/.karnel-managed"
  return 0
}

_compile_kilocode_helper() {
  loading "Compiling helper" _compile_kilocode_helper_impl
}

_compile_kilocode_helper_impl() {
  local HELPER_SRC="$KARNEL_PATH/tools/ai/kilocode-cli/helper/kilocode_helper.c"
  if [ ! -f "$HELPER_SRC" ]; then
    log_error "Helper source not found at $HELPER_SRC"
    return 1
  fi

  mkdir -p "$PREFIX/bin" || return 1
  local temporary
  temporary="$(mktemp "$PREFIX/bin/.kilocode.XXXXXX")" || return 1
  if ! cc -O2 -o "$temporary" "$HELPER_SRC" &>>"$LOG_FILE"; then
    rm -f "$temporary"
    log_error "Failed to compile kilocode helper"
    return 1
  fi

  chmod +x "$temporary"
  mv -f "$temporary" "$PREFIX/bin/kilocode" || return 1

  ln -sf "$PREFIX/bin/kilocode" "$PREFIX/bin/kilo"
  sha256sum "$PREFIX/bin/kilocode" >"$KILOCODE_DATA_DIR/.karnel-wrapper-kilocode" || return 1

  return 0
}

_install_kilocode_native() {
  _install_kilocode_deps || return 1
  _download_kilocode_binary || return 1
  _compile_kilocode_helper || return 1
  log_success "Kilo Code CLI installed natively"
  return 0
}

install_kilocode_cli() {
  if _kilocode_wrapper_owned && _kilocode_data_owned; then
    log_info "Kilo Code CLI is already installed"
    return 2
  fi

  _kilocode_verify_ownership || return 1

  _install_kilocode_native
}

uninstall_kilocode_cli() {
  mkdir -p "$(dirname "$LOG_FILE")"

  if ! _kilocode_wrapper_owned && ! _kilocode_alias_owned && ! _kilocode_data_owned; then
    log_warn "Kilo Code CLI is not installed"
    return 2
  fi

  loading "Uninstalling Kilo Code CLI" _uninstall_kilocode_cli_impl || return 1
}

_uninstall_kilocode_cli_impl() {
  _kilocode_alias_owned && rm -f "$PREFIX/bin/kilo"
  _kilocode_wrapper_owned && rm -f "$PREFIX/bin/kilocode"
  _kilocode_data_owned && rm -rf "$KILOCODE_DATA_DIR"
  log_success "Kilo Code CLI uninstalled"
}

update_kilocode_cli() {
  _check_update_needed "Kilo Code CLI" "$(_get_installed_version kilocode)" "$(_get_remote_github_version Kilo-Org/kilocode)" _install_kilocode_native
}

reinstall_kilocode_cli() {
  uninstall_kilocode_cli || [[ $? -eq 2 ]] || return 1
  install_kilocode_cli
}
