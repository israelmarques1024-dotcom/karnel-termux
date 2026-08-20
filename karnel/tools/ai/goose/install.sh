#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/version"
import "@/utils/install"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
GOOSE_DATA_DIR="$HOME/.local/share/karnel-data/goose"
GOOSE_BIN_PATH="$PREFIX/bin/goose"
GOOSE_MARKER="$GOOSE_DATA_DIR/.karnel-managed"
GOOSE_BIN_MARKER="$GOOSE_DATA_DIR/.karnel-binary"

_get_latest_goose_version() {
  local raw
  raw=$(_spin_capture "Checking GitHub" curl -fsSL "https://api.github.com/repos/aaif-goose/goose/releases/latest" 2>/dev/null)
  echo "$raw" | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' 2>/dev/null
}

_get_latest_goose_version_silent() {
  curl -fsSL "https://api.github.com/repos/aaif-goose/goose/releases/latest" 2>/dev/null | \
    grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/'
}

_goose_download_binary() {
  loading "Downloading Goose CLI" _goose_download_binary_impl
}

_goose_download_binary_impl() {
  if [ -x "$GOOSE_BIN_PATH" ] && [ "${1:-}" != "force" ]; then
    return 0
  fi

  local latest_version
  latest_version=$(_get_latest_goose_version_silent)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Goose version"
    return 1
  fi

  local arch
  arch=$(uname -m)
  local arch_suffix
  case "$arch" in
    aarch64|arm64) arch_suffix="aarch64-unknown-linux-musl" ;;
    x86_64) arch_suffix="x86_64-unknown-linux-musl" ;;
    *) log_error "Unsupported Goose architecture: $arch"; return 1 ;;
  esac

  local tarball="goose-${arch_suffix}.tar.gz"
  local download_url="https://github.com/aaif-goose/goose/releases/download/v${latest_version}/${tarball}"

  local staging_dir old_data old_bin goose_bin
  mkdir -p "$(dirname "$GOOSE_DATA_DIR")" "$(dirname "$GOOSE_BIN_PATH")"
  staging_dir=$(mktemp -d "$(dirname "$GOOSE_DATA_DIR")/.goose.XXXXXX") || return 1

  if { [ -e "$GOOSE_DATA_DIR" ] || [ -e "$GOOSE_BIN_PATH" ]; } &&
    { [ ! -f "$GOOSE_MARKER" ] || ! managed_file_matches "$GOOSE_BIN_PATH" "$GOOSE_BIN_MARKER"; }; then
    rm -rf "$staging_dir"
    log_error "Refusing to replace a Goose installation not owned by Karnel"
    return 1
  fi

  if ! curl -fsSL "$download_url" -o "$staging_dir/$tarball" &>>"$LOG_FILE"; then
    rm -rf "$staging_dir"
    log_error "Failed to download Goose CLI"
    return 1
  fi

  if ! verify_github_release_asset aaif-goose/goose "v${latest_version}" "$tarball" "$staging_dir/$tarball" ||
    ! extract_tarball "$staging_dir/$tarball" "$staging_dir"; then
    rm -rf "$staging_dir"
    return 1
  fi

  goose_bin=$(find "$staging_dir" -name "goose" -type f 2>/dev/null | head -1)
  if [ -z "$goose_bin" ]; then
    rm -rf "$staging_dir"
    log_error "Goose binary not found after extraction"
    return 1
  fi

  cp "$goose_bin" "$staging_dir/.goose-bin" || { rm -rf "$staging_dir"; return 1; }
  chmod +x "$staging_dir/.goose-bin"
  printf '%s\n' 'karnel-managed-v1' >"$staging_dir/.karnel-managed"

  if [ ! -x "$staging_dir/.goose-bin" ]; then
    rm -rf "$staging_dir"
    log_error "Goose CLI is not executable"
    return 1
  fi

  old_data="${GOOSE_DATA_DIR}.previous.$$"
  old_bin="${GOOSE_BIN_PATH}.previous.$$"
  if { [ -d "$GOOSE_DATA_DIR" ] && ! mv "$GOOSE_DATA_DIR" "$old_data"; } ||
    { [ -e "$GOOSE_BIN_PATH" ] && ! mv "$GOOSE_BIN_PATH" "$old_bin"; } ||
    ! mv "$staging_dir" "$GOOSE_DATA_DIR" ||
    ! mv "$GOOSE_DATA_DIR/.goose-bin" "$GOOSE_BIN_PATH"; then
    rm -rf "$staging_dir" "$GOOSE_DATA_DIR"
    [[ -e "$old_bin" ]] && mv "$old_bin" "$GOOSE_BIN_PATH"
    [[ -d "$old_data" ]] && mv "$old_data" "$GOOSE_DATA_DIR"
    log_error "Failed to replace Goose CLI"
    return 1
  fi
  rm -rf "$old_data" "$old_bin"
  record_managed_file "$GOOSE_BIN_PATH" "$GOOSE_BIN_MARKER" || return 1

  return 0
}

install_goose() {
  if command -v goose &>/dev/null; then
    log_info "Goose CLI is already installed"
    return 2
  fi
  if [ -e "$GOOSE_BIN_PATH" ]; then
    log_error "Refusing to replace an existing Goose binary not owned by Karnel"
    return 1
  fi

  local SELECTED_METHOD
  read_select "Installation method" SELECTED_METHOD \
    "Native (recommended) - Termux binary" \
    "glibc + proot (bad system call)"

  case "$SELECTED_METHOD" in
  *Native*)
    _goose_download_binary || return 1
    if command -v goose &>/dev/null; then
      log_success "Goose CLI installed (native Termux)"
      log_info "Run: ${D_CYAN}goose session${NC}"
      log_info "First-time setup: ${D_CYAN}goose configure${NC}"
      return 0
    fi
    log_error "Goose CLI installation failed"
    return 1
    ;;
  *proot*)
    _install_goose_proot_glibc
    return $?
    ;;
  esac
}

_install_goose_proot_glibc() {
  if ! command -v proot &>/dev/null; then
    if ! yes | pkg install proot &>>"$LOG_FILE"; then
      log_error "Failed to install proot"
      return 1
    fi
  fi
  _goose_download_binary_proot || return 1

  local wrapper_src="$KARNEL_PATH/tools/ai/goose/bin/goose.proot"
  if [ ! -f "$wrapper_src" ]; then
    log_error "Wrapper template not found at $wrapper_src"
    return 1
  fi
  if [ -e "$GOOSE_BIN_PATH" ] && ! managed_file_matches "$GOOSE_BIN_PATH" "$GOOSE_BIN_MARKER"; then
    log_error "Refusing to replace an existing Goose binary not owned by Karnel"
    return 1
  fi
  sed "s|__DATA_DIR__|$GOOSE_DATA_DIR|g" "$wrapper_src" >"$GOOSE_BIN_PATH"
  chmod +x "$GOOSE_BIN_PATH"
  record_managed_file "$GOOSE_BIN_PATH" "$GOOSE_BIN_MARKER" || return 1
  log_success "Goose CLI installed (glibc + proot)"
  return 0
}

_goose_download_binary_proot() {
  loading "Downloading Goose CLI" _goose_download_binary_proot_impl
}

_goose_download_binary_proot_impl() {
  local latest_version
  latest_version=$(_get_latest_goose_version_silent)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Goose version"
    return 1
  fi

  local arch
  arch=$(uname -m)
  local arch_suffix
  case "$arch" in
    aarch64|arm64) arch_suffix="aarch64-unknown-linux-musl" ;;
    x86_64) arch_suffix="x86_64-unknown-linux-musl" ;;
    *) log_error "Unsupported Goose architecture: $arch"; return 1 ;;
  esac

  local tarball="goose-${arch_suffix}.tar.gz"
  local download_url="https://github.com/aaif-goose/goose/releases/download/v${latest_version}/${tarball}"

  mkdir -p "$GOOSE_DATA_DIR"
  if ! curl -fsSL "$download_url" -o "$GOOSE_DATA_DIR/$tarball" &>>"$LOG_FILE"; then
    log_error "Failed to download Goose CLI"
    return 1
  fi
  if ! tar -xzf "$GOOSE_DATA_DIR/$tarball" -C "$GOOSE_DATA_DIR" &>>"$LOG_FILE"; then
    rm -f "$GOOSE_DATA_DIR/$tarball"
    log_error "Failed to extract Goose CLI"
    return 1
  fi
  rm -f "$GOOSE_DATA_DIR/$tarball"
  local goose_bin
  goose_bin=$(find "$GOOSE_DATA_DIR" -name "goose" -type f 2>/dev/null | head -1)
  if [ -z "$goose_bin" ] || [ "$goose_bin" == "$GOOSE_DATA_DIR/goose" ]; then
    log_error "Goose binary not found after extraction"
    return 1
  fi
  mv "$goose_bin" "$GOOSE_DATA_DIR/goose"
  chmod +x "$GOOSE_DATA_DIR/goose"
  return 0
}

uninstall_goose() {
  if [ ! -f "$PREFIX/bin/goose" ]; then
    log_info "Goose CLI is not installed"
    return 2
  fi

  if [ ! -f "$GOOSE_MARKER" ] || ! managed_file_matches "$GOOSE_BIN_PATH" "$GOOSE_BIN_MARKER"; then
    log_error "Refusing to remove a Goose installation not owned by Karnel"
    return 1
  fi
  rm -f "$GOOSE_BIN_PATH"
  rm -rf "$GOOSE_DATA_DIR"

  log_success "Goose CLI uninstalled"
  return 0
}

update_goose() {
  _check_update_needed "Goose CLI" \
    "$(_get_installed_version goose 2>/dev/null || echo 0)" \
    "$(_parse_version "$(_get_latest_goose_version_silent)")" \
    _update_goose_impl
}

_update_goose_impl() {
  _goose_download_binary_impl force
}

reinstall_goose() {
  if command -v goose &>/dev/null; then
    _goose_download_binary_impl force
  else
    install_goose
  fi
}
