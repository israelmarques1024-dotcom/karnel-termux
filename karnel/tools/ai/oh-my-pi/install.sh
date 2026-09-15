#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/version"
import "@/utils/install"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
OMP_DATA_DIR="$HOME/.local/share/karnel-data/oh-my-pi"

_omp_detect_ubuntu_root() {
  local root
  root="$(find /data/data/com.termux -maxdepth 10 -type d \
    -name "rootfs" -path "*/containers/ubuntu/*" 2>/dev/null | head -1)"
  if [ -z "$root" ]; then
    root="$(find /data/data/com.termux -maxdepth 10 -type d \
      -name "ubuntu" -path "*/installed-rootfs/*" 2>/dev/null | head -1)"
  fi
  echo "$root"
}

_omp_proot_ubuntu() {
  proot-distro login --shared-tmp ubuntu -- "$@"
}

_get_latest_omp_version() {
  local raw
  raw=$(_spin_capture "Checking GitHub" curl -fsSL "https://api.github.com/repos/can1357/oh-my-pi/releases?per_page=5" 2>/dev/null)
  echo "$raw" | jq -r '[.[] | select(.tag_name | startswith("v"))][0].tag_name' 2>/dev/null
}

_get_latest_omp_version_silent() {
  local raw
  raw=$(curl -fsSL "https://api.github.com/repos/can1357/oh-my-pi/releases?per_page=5" 2>/dev/null)
  echo "$raw" | jq -r '[.[] | select(.tag_name | startswith("v"))][0].tag_name' 2>/dev/null
}

_omp_install_deps_native() {
  loading "Installing glibc and dependencies" _omp_install_deps_native_impl
}

_omp_install_deps_native_impl() {
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
    ["jq"]="jq" ["curl"]="curl" ["tar"]="tar" ["clang"]="clang"
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

_download_omp_binary() {
  loading "Downloading Oh-My-Pi standalone binary" _download_omp_binary_impl
}

_download_omp_binary_impl() {
  local target_dir="${1:-$OMP_DATA_DIR}"
  local latest_version
  latest_version=$(_get_latest_omp_version_silent)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Oh-My-Pi version"
    return 1
  fi
  mkdir -p "$target_dir"
  local download_url="https://github.com/can1357/oh-my-pi/releases/download/$latest_version/omp-linux-arm64"
  if ! curl -fsSL "$download_url" -o "$target_dir/omp" &>>"$LOG_FILE"; then
    log_error "Failed to download Oh-My-Pi binary"
    return 1
  fi
  local expected
  expected=$(github_release_asset_sha256 can1357/oh-my-pi "$latest_version" "omp-linux-arm64") || expected=""
  if [[ "$expected" =~ ^[0-9a-f]{64}$ ]]; then
    verify_sha256 "$target_dir/omp" "$expected" || return 1
  else
    log_error "No published SHA-256 for Oh-My-Pi; refusing install (integrity cannot be verified)"
    return 1
  fi
  chmod +x "$target_dir/omp"
  echo "$latest_version" > "$target_dir/version"
  : > "$target_dir/.karnel-managed"
  return 0
}

_compile_omp_helper() {
  loading "Compiling omp helper" _compile_omp_helper_impl
}

_compile_omp_helper_impl() {
  local output="${1:-$PREFIX/bin/omp}"
  local HELPER_SRC="$KARNEL_PATH/tools/ai/oh-my-pi/helper/omp_helper.c"
  if [ ! -f "$HELPER_SRC" ]; then
    log_error "Helper source not found at $HELPER_SRC"
    return 1
  fi
  if ! clang -O2 -o "$output" "$HELPER_SRC" &>>"$LOG_FILE"; then
    log_error "Failed to compile omp helper"
    return 1
  fi
  chmod +x "$output"
  return 0
}

_install_omp_native() {
  local staging_dir old_data old_bin
  _omp_install_deps_native || return 1
  mkdir -p "$(dirname "$OMP_DATA_DIR")" "$PREFIX/bin"
  staging_dir=$(mktemp -d "$(dirname "$OMP_DATA_DIR")/.oh-my-pi.XXXXXX") || return 1
  if ! _download_omp_binary_impl "$staging_dir/data" ||
    ! _compile_omp_helper_impl "$staging_dir/omp" ||
    [[ ! -x "$staging_dir/data/omp" || ! -x "$staging_dir/omp" ]]; then
    rm -rf "$staging_dir"
    return 1
  fi

  old_data="${OMP_DATA_DIR}.previous.$$"
  old_bin="$PREFIX/bin/omp.previous.$$"
  if { [ -d "$OMP_DATA_DIR" ] && ! mv "$OMP_DATA_DIR" "$old_data"; } ||
    { [ -e "$PREFIX/bin/omp" ] && ! mv "$PREFIX/bin/omp" "$old_bin"; } ||
    ! mv "$staging_dir/data" "$OMP_DATA_DIR" ||
    ! mv "$staging_dir/omp" "$PREFIX/bin/omp"; then
    rm -rf "$staging_dir" "$OMP_DATA_DIR"
    [[ -e "$old_bin" ]] && mv "$old_bin" "$PREFIX/bin/omp"
    [[ -d "$old_data" ]] && mv "$old_data" "$OMP_DATA_DIR"
    log_error "Failed to replace Oh-My-Pi"
    return 1
  fi
  rm -rf "$staging_dir" "$old_data" "$old_bin"
  log_success "Oh-My-Pi (omp) installed natively"
  return 0
}

_install_omp_proot() {
  loading "Installing Oh-My-Pi (proot-distro)" _install_omp_proot_impl
}

_install_omp_proot_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! command -v proot-distro &>/dev/null; then
    yes | pkg install proot-distro &>>"$LOG_FILE"
  fi
  if [ ! -d "$(_omp_detect_ubuntu_root)" ]; then
    proot-distro install ubuntu:24.04 &>>"$LOG_FILE"
  fi
  _omp_proot_ubuntu /bin/bash -c \
    'apt-get update && apt-get upgrade -y && apt-get install -y curl ca-certificates tar' \
    &>>"$LOG_FILE"
  local latest_version
  latest_version=$(_get_latest_omp_version_silent)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Oh-My-Pi version"
    return 1
  fi
  local download_url="https://github.com/can1357/oh-my-pi/releases/download/$latest_version/omp-linux-arm64"
  local expected
  expected=$(github_release_asset_sha256 can1357/oh-my-pi "$latest_version" "omp-linux-arm64") || expected=""
  if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
    log_error "No published SHA-256 for Oh-My-Pi; refusing install (integrity cannot be verified)"
    return 1
  fi
  if ! _omp_proot_ubuntu /bin/bash -c '
    d=$(mktemp -d) &&
    curl -fsSL "$1" -o "$d/omp" &&
    { [ -z "$2" ] || [ "$(sha256sum "$d/omp" | awk "{print \$1}")" = "$2" ]; } &&
    chmod +x "$d/omp" &&
    test -x "$d/omp" &&
    mkdir -p /usr/local/bin &&
    mv "$d/omp" /usr/local/bin/omp &&
    rm -rf "$d"
  ' bash "$download_url" "$expected" &>>"$LOG_FILE"; then
    log_error "Failed to install Oh-My-Pi binary"
    return 1
  fi
  local ubuntu_root
  ubuntu_root="$(_omp_detect_ubuntu_root)"
  if [ -z "$ubuntu_root" ]; then
    log_error "Ubuntu rootfs not found"
    return 1
  fi
  local omp_bin="$ubuntu_root/usr/local/bin/omp"
  if [ ! -f "$omp_bin" ]; then
    log_error "Oh-My-Pi binary not found after install"
    return 1
  fi
  local wrapper_src="$KARNEL_PATH/tools/ai/oh-my-pi/bin/omp"
  if [ ! -f "$wrapper_src" ]; then
    log_error "Wrapper template not found at $wrapper_src"
    return 1
  fi
  sed "s|__UBUNTU_ROOTFS__|$ubuntu_root|g" "$wrapper_src" >"$PREFIX/bin/omp"
  chmod +x "$PREFIX/bin/omp"
  return 0
}

install_oh_my_pi() {
  if command -v omp &>/dev/null; then
    log_info "Oh-My-Pi (omp) is already installed"
    return 2
  fi
  log_info "Select installation method for Oh-My-Pi:"
  read_select "Installation method" SELECTED_METHOD \
    "Native (recommended) - Compile with glibc support" \
    "Proot-distro (alternative) - Ubuntu container"
  case "$SELECTED_METHOD" in
  *Native*) _install_omp_native ;;
  *Proot-distro*) _install_omp_proot ;;
  esac
}

_uninstall_omp_native_impl() {
  if [[ ! -f "$OMP_DATA_DIR/.karnel-managed" ]]; then
    log_error "Refusing to remove an Oh-My-Pi installation that is not managed by Karnel"
    return 1
  fi
  rm -f "$PREFIX/bin/omp"
  rm -rf "$OMP_DATA_DIR"
}

_omp_is_native() {
  [ -d "$OMP_DATA_DIR" ] && [ -f "$OMP_DATA_DIR/omp" ]
}

_omp_is_proot() {
  local root
  root="$(_omp_detect_ubuntu_root)"
  [ -n "$root" ] && [ -f "$root/usr/local/bin/omp" ]
}

uninstall_oh_my_pi() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if _omp_is_native; then
    loading "Uninstalling Oh-My-Pi (native)" _uninstall_omp_native_impl || return 1
    log_success "Oh-My-Pi (native) uninstalled"
  elif _omp_is_proot; then
    loading "Uninstalling Oh-My-Pi (proot-distro)" _uninstall_omp_proot_impl || return 1
    log_success "Oh-My-Pi (proot-distro) uninstalled"
  else
    log_info "Oh-My-Pi is not installed"
    return 2
  fi
  return 0
}

_uninstall_omp_proot_impl() {
  _omp_proot_ubuntu /bin/bash -c 'rm -f /usr/local/bin/omp' &>>"$LOG_FILE"
  rm -f "$PREFIX/bin/omp"
  return 0
}

_update_omp_native_impl() {
  _install_omp_native
}

_update_omp_proot_impl() {
  local latest_version
  latest_version=$(_get_latest_omp_version_silent)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Oh-My-Pi version"
    return 1
  fi
  local download_url="https://github.com/can1357/oh-my-pi/releases/download/$latest_version/omp-linux-arm64"
  local expected
  expected=$(github_release_asset_sha256 can1357/oh-my-pi "$latest_version" "omp-linux-arm64") || expected=""
  if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
    log_error "No published SHA-256 for Oh-My-Pi; refusing install (integrity cannot be verified)"
    return 1
  fi
  if ! _omp_proot_ubuntu /bin/bash -c '
    d=$(mktemp -d) &&
    curl -fsSL "$1" -o "$d/omp" &&
    { [ -z "$2" ] || [ "$(sha256sum "$d/omp" | awk "{print \$1}")" = "$2" ]; } &&
    chmod +x "$d/omp" &&
    test -x "$d/omp" &&
    mv "$d/omp" /usr/local/bin/omp &&
    rm -rf "$d"
  ' bash "$download_url" "$expected" &>>"$LOG_FILE"; then
    log_error "Failed to update Oh-My-Pi binary"
    return 1
  fi
  local ubuntu_root
  ubuntu_root="$(_omp_detect_ubuntu_root)"
  if [ ! -f "$ubuntu_root/usr/local/bin/omp" ]; then
    log_error "Oh-My-Pi binary not found after update"
    return 1
  fi
  log_success "Oh-My-Pi (proot-distro) updated"
  return 0
}

_update_omp_impl() {
  if _omp_is_native; then
    _update_omp_native_impl
    return $?
  fi
  if _omp_is_proot; then
    loading "Updating Oh-My-Pi (proot-distro)" _update_omp_proot_impl
    return $?
  fi
  log_warn "Could not detect Oh-My-Pi installation method"
  return 1
}

update_oh_my_pi() {
  _check_update_needed "Oh-My-Pi" "$(_get_installed_version omp)" "$(_get_latest_omp_version)" _update_omp_impl
}

reinstall_oh_my_pi() {
  uninstall_oh_my_pi
  install_oh_my_pi
}
