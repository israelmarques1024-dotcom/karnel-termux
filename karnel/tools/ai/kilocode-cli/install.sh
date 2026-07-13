#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/colors"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
KILOCODE_DATA_DIR="$HOME/.local/share/karnel-data/kilocode"

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
    ["clang"]="clang"
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

  mkdir -p "$KILOCODE_DATA_DIR"

  local tarball="kilo-linux-arm64.tar.gz"
  local download_url="https://github.com/Kilo-Org/kilocode/releases/download/$latest_version/$tarball"

  if ! curl -fsSL "$download_url" -o "$KILOCODE_DATA_DIR/$tarball" &>>"$LOG_FILE"; then
    log_error "Failed to download Kilo Code CLI binary"
    return 1
  fi

  if ! tar -zxf "$KILOCODE_DATA_DIR/$tarball" -C "$KILOCODE_DATA_DIR" &>>"$LOG_FILE"; then
    log_error "Failed to extract Kilo Code CLI binary"
    return 1
  fi

  rm -f "$KILOCODE_DATA_DIR/$tarball"

  if [ ! -f "$KILOCODE_DATA_DIR/kilo" ]; then
    log_error "Kilo Code CLI binary not found after extraction"
    return 1
  fi

  chmod +x "$KILOCODE_DATA_DIR/kilo"
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

  if ! clang -O2 -o "$PREFIX/bin/kilocode" "$HELPER_SRC" &>>"$LOG_FILE"; then
    log_error "Failed to compile kilocode helper"
    return 1
  fi

  chmod +x "$PREFIX/bin/kilocode"

  ln -sf "$PREFIX/bin/kilocode" "$PREFIX/bin/kilo"

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
  if command -v kilocode &>/dev/null; then
    log_info "Kilo Code CLI is already installed"
    return 2
  fi

  _install_kilocode_native
}

uninstall_kilocode_cli() {
  mkdir -p "$(dirname "$LOG_FILE")"

  if [ ! -f "$PREFIX/bin/kilocode" ]; then
    log_warn "Kilo Code CLI is not installed"
    return 1
  fi

  loading "Uninstalling Kilo Code CLI" _uninstall_kilocode_cli_impl
}

_uninstall_kilocode_cli_impl() {
  if [ -f "$KILOCODE_DATA_DIR/kilo" ]; then
    rm -f "$PREFIX/bin/kilocode" "$PREFIX/bin/kilo"
    rm -rf "$KILOCODE_DATA_DIR"
    log_success "Kilo Code CLI uninstalled"
    return 0
  fi

  if rm -f "$PREFIX/bin/kilocode" "$PREFIX/bin/kilo" &>>"$LOG_FILE"; then
    log_success "Kilo Code CLI uninstalled"
    return 0
  else
    log_error "Failed to uninstall Kilo Code CLI"
    return 1
  fi
}

update_kilocode_cli() {
  _check_update_needed "Kilo Code CLI" "$(_get_installed_version kilocode)" "$(_get_remote_github_version Kilo-Org/kilocode)" _install_kilocode_native
}

reinstall_kilocode_cli() {
  uninstall_kilocode_cli
  install_kilocode_cli
}
