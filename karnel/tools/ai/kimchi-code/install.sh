#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/version"
import "@/utils/colors"
import "@/utils/install"
import "@/utils/uninstall"

: "${KARNEL_DATA:=${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data}"
LOG_FILE="$KARNEL_CACHE/install_ai.log"
KIMCHI_DATA_DIR="$KARNEL_DATA/kimchi"
KIMCHI_BIN_PATH="$KIMCHI_DATA_DIR/bin/kimchi"
KIMCHI_MARKER=".karnel-managed"
KIMCHI_WRAPPER_MARKER="$KIMCHI_DATA_DIR/.karnel-wrapper"

_kimchi_data_owned() {
  [[ -f "$KIMCHI_DATA_DIR/$KIMCHI_MARKER" ]]
}

_kimchi_wrapper_owned() {
  [[ -f "$KIMCHI_WRAPPER_MARKER" && -f "$PREFIX/bin/kimchi" ]] || return 1
  [[ "$(sha256sum "$PREFIX/bin/kimchi" 2>/dev/null)" == "$(<"$KIMCHI_WRAPPER_MARKER")" ]]
}

_kimchi_verify_ownership() {
  if [[ -e "$KIMCHI_DATA_DIR" ]] && ! _kimchi_data_owned; then
    log_error "Refusing to replace unowned Kimchi data: $KIMCHI_DATA_DIR"
    return 1
  fi
  if [[ -e "$PREFIX/bin/kimchi" ]] && ! _kimchi_wrapper_owned; then
    log_error "Refusing to replace unowned command: $PREFIX/bin/kimchi"
    return 1
  fi
  if command -v kimchi &>/dev/null && ! _kimchi_wrapper_owned; then
    log_error "Refusing to shadow the existing kimchi command: $(command -v kimchi)"
    return 1
  fi
}

_kimchi_detect_ubuntu_root() {
  local root
  root="$(find /data/data/com.termux -maxdepth 10 -type d \
    -name "rootfs" -path "*/containers/ubuntu/*" 2>/dev/null | head -1)"
  if [ -z "$root" ]; then
    root="$(find /data/data/com.termux -maxdepth 10 -type d \
      -name "ubuntu" -path "*/installed-rootfs/*" 2>/dev/null | head -1)"
  fi
  echo "$root"
}

_kimchi_proot_ubuntu() {
  proot-distro login --shared-tmp ubuntu -- "$@"
}

_get_latest_kimchi_version() {
  curl -fsSL https://api.github.com/repos/getkimchi/kimchi/releases/latest 2>/dev/null |
    grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

_kimchi_install_deps_native() {
  loading "Installing glibc and dependencies" _kimchi_install_deps_native_impl
}

_kimchi_install_deps_native_impl() {
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

_download_kimchi_binary() {
  loading "Downloading Kimchi" _download_kimchi_binary_impl
}

_download_kimchi_binary_impl() {
  local latest_version arch kimchi_arch tarball download_url staging_dir expected actual
  latest_version=$(_get_latest_kimchi_version)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Kimchi version"
    return 1
  fi

  arch=$(uname -m)
  case "$arch" in
    aarch64|arm64) kimchi_arch="arm64" ;;
    x86_64) kimchi_arch="amd64" ;;
    *) log_error "Unsupported Kimchi architecture: $arch"; return 1 ;;
  esac

  tarball="kimchi_linux_${kimchi_arch}.tar.gz"
  download_url="https://github.com/getkimchi/kimchi/releases/download/${latest_version}/${tarball}"
  mkdir -p "$(dirname "$KIMCHI_DATA_DIR")"
  staging_dir=$(mktemp -d "$(dirname "$KIMCHI_DATA_DIR")/.kimchi.XXXXXX") || return 1

  if ! curl -fsSL "$download_url" -o "$staging_dir/$tarball" &>>"$LOG_FILE"; then
    rm -rf "$staging_dir"
    log_error "Failed to download Kimchi binary"
    return 1
  fi

  expected=$(github_release_asset_sha256 getkimchi/kimchi "$latest_version" "$tarball") || expected=""
  actual=$(sha256sum "$staging_dir/$tarball" 2>>"$LOG_FILE") || { rm -rf "$staging_dir"; return 1; }
  if [[ ! "$expected" =~ ^[0-9a-f]{64}$ || "${actual%% *}" != "$expected" ]] ||
    ! extract_tarball "$staging_dir/$tarball" "$staging_dir"; then
    rm -rf "$staging_dir"
    log_error "Kimchi archive failed official SHA-256 validation"
    return 1
  fi

  if [ ! -f "$staging_dir/bin/kimchi" ]; then
    local found
    found=$(find "$staging_dir" -name "kimchi" -type f -executable 2>/dev/null | head -1)
    if [ -z "$found" ]; then
      log_error "Kimchi binary not found after extraction"
      rm -rf "$staging_dir"
      return 1
    fi
    mkdir -p "$staging_dir/bin"
    mv "$found" "$staging_dir/bin/kimchi"
  fi
  chmod +x "$staging_dir/bin/kimchi"

  replace_managed_directory "$staging_dir" "$KIMCHI_DATA_DIR" "$KIMCHI_MARKER"

  # Kimchi expects auxiliary files at ~/.local/share/kimchi
  local kimchi_share_src="$KIMCHI_DATA_DIR/share/kimchi"
  local kimchi_share_dst="$HOME/.local/share/kimchi"
  if [ -d "$kimchi_share_src" ]; then
    rm -rf "$kimchi_share_dst"
    ln -sf "$kimchi_share_src" "$kimchi_share_dst"
  fi
  return 0
}

# ===== NATIVE (glibc helper) =====

_compile_kimchi_helper() {
  loading "Compiling helper" _compile_kimchi_helper_impl
}

_compile_kimchi_helper_impl() {
  local HELPER_SRC="$KARNEL_PATH/tools/ai/kimchi-code/helper/kimchi_helper.c"
  local temporary
  temporary="$(mktemp "$PREFIX/bin/.kimchi.XXXXXX")" || return 1
  if ! clang -O2 -o "$temporary" "$HELPER_SRC" &>>"$LOG_FILE"; then
    rm -f "$temporary"
    log_error "Failed to compile kimchi helper"
    return 1
  fi
  chmod +x "$temporary"
  mv -f "$temporary" "$PREFIX/bin/kimchi" || return 1
  record_managed_file "$PREFIX/bin/kimchi" "$KIMCHI_WRAPPER_MARKER"
  return 0
}

_install_kimchi_native() {
  _kimchi_install_deps_native || return 1
  _download_kimchi_binary || return 1
  _compile_kimchi_helper || return 1
  printf 'native' >"$KIMCHI_DATA_DIR/.install-method"
  log_success "Kimchi installed natively"
  return 0
}

# ===== GLIBC + PROOT =====

_kimchi_install_proot_pkg() {
  if ! command -v proot &>/dev/null; then
    if ! yes | pkg install proot &>>"$LOG_FILE"; then
      log_error "Failed to install proot"
      return 1
    fi
  fi
  return 0
}

_kimchi_create_proot_wrapper() {
  local wrapper_src="$KARNEL_PATH/tools/ai/kimchi-code/bin/kimchi.proot"
  if [ ! -f "$wrapper_src" ]; then
    log_error "Wrapper template not found at $wrapper_src"
    return 1
  fi
  sed "s|__DATA_DIR__|$KIMCHI_DATA_DIR|g" "$wrapper_src" >"$PREFIX/bin/kimchi"
  chmod +x "$PREFIX/bin/kimchi"
  record_managed_file "$PREFIX/bin/kimchi" "$KIMCHI_WRAPPER_MARKER"
  return 0
}

_install_kimchi_proot_glibc() {
  _kimchi_install_deps_native || return 1
  loading "Installing proot" _kimchi_install_proot_pkg || return 1
  _download_kimchi_binary || return 1
  loading "Creating proot wrapper" _kimchi_create_proot_wrapper || return 1
  printf 'proot-glibc' >"$KIMCHI_DATA_DIR/.install-method"
  log_success "Kimchi installed with glibc + proot"
  return 0
}

# ===== PROOT-DISTRO =====

_kimchi_install_proot_distro() {
  if ! command -v proot-distro &>/dev/null; then
    if ! yes | pkg install proot-distro &>>"$LOG_FILE"; then
      log_error "Failed to install proot-distro"
      return 1
    fi
  fi
  return 0
}

_kimchi_install_ubuntu() {
  if [ ! -d "$(_kimchi_detect_ubuntu_root)" ]; then
    if ! proot-distro install ubuntu:24.04 &>>"$LOG_FILE"; then
      log_error "Failed to install Ubuntu container"
      return 1
    fi
  fi
  return 0
}

_kimchi_ubuntu_deps() {
  _kimchi_proot_ubuntu /bin/bash -c \
    'apt-get update && apt-get upgrade -y && apt-get install -y curl ca-certificates tar' \
    &>>"$LOG_FILE"
}

_kimchi_ubuntu_install_bin() {
  local latest_version
  latest_version=$(_get_latest_kimchi_version)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Kimchi version"
    return 1
  fi

  local download_url="https://github.com/getkimchi/kimchi/releases/download/$latest_version/kimchi_linux_arm64.tar.gz"

  local expected
  expected=$(github_release_asset_sha256 getkimchi/kimchi "$latest_version" "kimchi_linux_arm64.tar.gz") || expected=""
  if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
    log_error "No published SHA-256 for Kimchi; refusing install (integrity cannot be verified)"
    return 1
  fi
  _kimchi_proot_ubuntu /bin/bash -c '
    mkdir -p /tmp/kimchi-install &&
    curl -fsSL "$1" -o /tmp/kimchi-install/kimchi.tar.gz &&
    { [ -z "$2" ] || [ "$(sha256sum /tmp/kimchi-install/kimchi.tar.gz | awk "{print \$1}")" = "$2" ]; } &&
    tar -zxf /tmp/kimchi-install/kimchi.tar.gz -C /tmp/kimchi-install &&
    mkdir -p /usr/local/bin /usr/local/share &&
    mv /tmp/kimchi-install/bin/kimchi /usr/local/bin/kimchi &&
    chmod +x /usr/local/bin/kimchi &&
    rm -rf /usr/local/share/kimchi &&
    mv /tmp/kimchi-install/share/kimchi /usr/local/share/kimchi &&
    rm -rf /tmp/kimchi-install
  ' bash "$download_url" "$expected" &>>"$LOG_FILE"

  local kimchi_bin
  kimchi_bin="$(_kimchi_detect_ubuntu_root)/usr/local/bin/kimchi"
  if [ ! -f "$kimchi_bin" ]; then
    log_error "Kimchi binary not found after install"
    return 1
  fi
  return 0
}

_kimchi_create_ubuntu_wrapper() {
  local ubuntu_root
  ubuntu_root="$(_kimchi_detect_ubuntu_root)"
  if [ -z "$ubuntu_root" ]; then
    log_error "Ubuntu rootfs not found"
    return 1
  fi

  local wrapper_src="$KARNEL_PATH/tools/ai/kimchi-code/bin/kimchi"
  if [ ! -f "$wrapper_src" ]; then
    log_error "Wrapper template not found at $wrapper_src"
    return 1
  fi
  sed "s|__UBUNTU_ROOTFS__|$ubuntu_root|g" "$wrapper_src" >"$PREFIX/bin/kimchi"
  chmod +x "$PREFIX/bin/kimchi"
  record_managed_file "$PREFIX/bin/kimchi" "$KIMCHI_WRAPPER_MARKER"
  return 0
}

_install_kimchi_proot() {
  mkdir -p "$(dirname "$LOG_FILE")"

  loading "Installing proot-distro" _kimchi_install_proot_distro || return 1
  loading "Installing Ubuntu container" _kimchi_install_ubuntu || return 1
  loading "Installing dependencies (Ubuntu)" _kimchi_ubuntu_deps || return 1
  loading "Downloading Kimchi (Ubuntu)" _kimchi_ubuntu_install_bin || return 1
  loading "Creating wrapper" _kimchi_create_ubuntu_wrapper || return 1

  mkdir -p "$KIMCHI_DATA_DIR"
  : >"$KIMCHI_DATA_DIR/$KIMCHI_MARKER"
  printf 'proot' >"$KIMCHI_DATA_DIR/.install-method"
  log_success "Kimchi installed (proot-distro)"
  return 0
}

# ===== MAIN INSTALL =====

install_kimchi_code() {
  if [ -f "$KIMCHI_DATA_DIR/.install-method" ]; then
    _update_kimchi_impl
    return $?
  fi
  _kimchi_verify_ownership || return 1

  if command -v kimchi &>/dev/null; then
    if _kimchi_wrapper_owned; then
      log_info "Kimchi is already installed"
      return 2
    fi
    _kimchi_verify_ownership || return 1
  fi
  if [ -e "$PREFIX/bin/kimchi" ]; then
    _kimchi_verify_ownership || return 1
  fi

  log_info "Select installation method for Kimchi:"

  local SELECTED_METHOD
  read_select "Installation method" SELECTED_METHOD \
    "glibc (recommended)" \
    "glibc + proot (bad system call)" \
    "proot-distro (ubuntu container)"

  case "$SELECTED_METHOD" in
  *"glibc + proot"*)
    _install_kimchi_proot_glibc
    ;;
  *"glibc (recommended)"*)
    _install_kimchi_native
    ;;
  *proot-distro*)
    _install_kimchi_proot
    ;;
  esac

  if _kimchi_wrapper_owned; then
    log_success "Kimchi CLI installed"
    log_info "Usage: ${D_CYAN}kimchi${NC} to launch the interactive TUI"
    log_info "Setup: ${D_CYAN}kimchi setup${NC} for first-time configuration"
    log_info "Docs:  ${D_CYAN}https://docs.kimchi.dev${NC}"
    return 0
  fi

  log_error "Kimchi CLI installation failed: binary not found or invalid"
  return 1
}

# ===== UNINSTALL =====

_uninstall_kimchi_impl() {
  local method="native"
  if [ -f "$KIMCHI_DATA_DIR/.install-method" ]; then
    method="$(cat "$KIMCHI_DATA_DIR/.install-method")"
  fi
  rm -f "$PREFIX/bin/kimchi"
  rm -rf "$KIMCHI_DATA_DIR"
  rm -f "$HOME/.local/share/kimchi"
  log_success "Kimchi ($method) uninstalled"
  return 0
}

uninstall_kimchi_code() {
  mkdir -p "$(dirname "$LOG_FILE")"

  if [ -f "$KIMCHI_DATA_DIR/.install-method" ]; then
    _kimchi_verify_ownership || return 1
    confirm_remove_paths "Kimchi" \
      "$HOME/.config/kimchi" \
      "$HOME/.local/share/kimchi" \
      "$HOME/.local/state/kimchi" \
      "$HOME/.cache/kimchi"
    # Also remove the binaries installed inside the ubuntu container for
    # proot/glibc installs (they are not cleaned by _uninstall_kimchi_impl).
    if [ -n "$(_kimchi_detect_ubuntu_root)" ] && _kimchi_wrapper_owned; then
      _kimchi_proot_ubuntu /bin/bash -c 'rm -f /usr/local/bin/kimchi && rm -rf /usr/local/share/kimchi' &>>"$LOG_FILE"
    fi
    loading "Uninstalling Kimchi" _uninstall_kimchi_impl
    rm -f "$PREFIX/bin/kimchi"
    return $?
  fi

  if [ -f "$KIMCHI_DATA_DIR/bin/kimchi" ] && _kimchi_wrapper_owned; then
    confirm_remove_paths "Kimchi" \
      "$HOME/.config/kimchi" \
      "$HOME/.local/share/kimchi" \
      "$HOME/.local/state/kimchi" \
      "$HOME/.cache/kimchi"
    loading "Uninstalling Kimchi" _uninstall_kimchi_impl
    return $?
  fi

  if [ -n "$(_kimchi_detect_ubuntu_root)" ] && _kimchi_wrapper_owned; then
    confirm_remove_paths "Kimchi" \
      "$HOME/.config/kimchi" \
      "$HOME/.local/share/kimchi" \
      "$HOME/.local/state/kimchi" \
      "$HOME/.cache/kimchi"
    _kimchi_proot_ubuntu /bin/bash -c 'rm -f /usr/local/bin/kimchi && rm -rf /usr/local/share/kimchi' &>>"$LOG_FILE"
    rm -f "$PREFIX/bin/kimchi"
    log_success "Kimchi (proot-distro) uninstalled"
    return 0
  fi

  if [ -e "$KIMCHI_DATA_DIR" ] || [ -e "$PREFIX/bin/kimchi" ]; then
    _kimchi_verify_ownership
    return $?
  fi
  log_info "Kimchi is not installed"
  return 2
}

# ===== UPDATE =====

_update_kimchi_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"

  if [ -f "$KIMCHI_DATA_DIR/.install-method" ]; then
    local method
    method="$(cat "$KIMCHI_DATA_DIR/.install-method")"
    case "$method" in
    proot-glibc)
      _install_kimchi_proot_glibc
      return $?
      ;;
    native)
      _install_kimchi_native
      return $?
      ;;
    proot)
      loading "Updating Kimchi (proot-distro)" _update_kimchi_proot_impl
      return $?
      ;;
    esac
  fi

  if [ -f "$KIMCHI_DATA_DIR/bin/kimchi" ]; then
    _install_kimchi_native
    return $?
  fi
  loading "Updating Kimchi (proot-distro)" _update_kimchi_proot_impl
}

update_kimchi_code() {
  _check_update_needed "Kimchi" "$(_get_installed_version kimchi)" "$(_get_remote_github_version getkimchi/kimchi)" _update_kimchi_impl
}

_update_kimchi_proot_impl() {
  local latest_version
  latest_version=$(_get_latest_kimchi_version)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Kimchi version"
    return 1
  fi

  local download_url="https://github.com/getkimchi/kimchi/releases/download/$latest_version/kimchi_linux_arm64.tar.gz"

  local expected
  expected=$(github_release_asset_sha256 getkimchi/kimchi "$latest_version" "kimchi_linux_arm64.tar.gz") || expected=""
  if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
    log_error "No published SHA-256 for Kimchi; refusing install (integrity cannot be verified)"
    return 1
  fi
  _kimchi_proot_ubuntu /bin/bash -c '
    mkdir -p /tmp/kimchi-install &&
    curl -fsSL "$1" -o /tmp/kimchi-install/kimchi.tar.gz &&
    { [ -z "$2" ] || [ "$(sha256sum /tmp/kimchi-install/kimchi.tar.gz | awk "{print \$1}")" = "$2" ]; } &&
    tar -zxf /tmp/kimchi-install/kimchi.tar.gz -C /tmp/kimchi-install &&
    rm -f /usr/local/bin/kimchi &&
    mv /tmp/kimchi-install/bin/kimchi /usr/local/bin/kimchi &&
    chmod +x /usr/local/bin/kimchi &&
    rm -rf /usr/local/share/kimchi &&
    mv /tmp/kimchi-install/share/kimchi /usr/local/share/kimchi &&
    rm -rf /tmp/kimchi-install
  ' bash "$download_url" "$expected" &>>"$LOG_FILE"

  local kimchi_bin
  kimchi_bin="$(_kimchi_detect_ubuntu_root)/usr/local/bin/kimchi"
  if [ ! -f "$kimchi_bin" ]; then
    log_error "Kimchi binary not found after update"
    return 1
  fi
  log_success "Kimchi (proot-distro) updated"
  return 0
}

# ===== REINSTALL =====

reinstall_kimchi_code() {
  uninstall_kimchi_code
  install_kimchi_code
}