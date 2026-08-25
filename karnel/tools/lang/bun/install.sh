#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/version"
import "@/utils/install"

LOG_FILE="$KARNEL_CACHE/install_lang.log"
BUN_DATA_DIR="$KARNEL_DATA/bun"
BUN_REPO="oven-sh/bun"

_bun_wrapper_owned() {
  local name="$1"
  local marker="$BUN_DATA_DIR/.karnel-wrapper-$name"
  [[ -f "$marker" && -f "$PREFIX/bin/$name" ]] || return 1
  [[ "$(sha256sum "$PREFIX/bin/$name" 2>/dev/null)" == "$(<"$marker")" ]]
}

_bun_shim_owned() {
  local marker="$BUN_DATA_DIR/.karnel-shim"
  [[ -f "$marker" && -f "$PREFIX/lib/bun-shim.so" ]] || return 1
  [[ "$(sha256sum "$PREFIX/lib/bun-shim.so" 2>/dev/null)" == "$(<"$marker")" ]]
}

_bun_bunx_owned() {
  [[ -f "$BUN_DATA_DIR/.karnel-wrapper-bunx" && -L "$PREFIX/bin/bunx" ]] || return 1
  [[ "$(readlink "$PREFIX/bin/bunx")" == "$(<"$BUN_DATA_DIR/.karnel-wrapper-bunx")" ]]
}

_bun_verify_native_ownership() {
  local path name
  if [[ -e "$BUN_DATA_DIR" && ! -f "$BUN_DATA_DIR/.karnel-managed" ]]; then
    log_error "Refusing to replace unowned data directory: $BUN_DATA_DIR"
    return 1
  fi
  for name in bun; do
    path="$PREFIX/bin/$name"
    if [[ -e "$path" ]] && ! _bun_wrapper_owned "$name"; then
      log_error "Refusing to replace unowned command: $path"
      return 1
    fi
  done
  if [[ -e "$PREFIX/bin/bunx" ]] && ! _bun_bunx_owned; then
    log_error "Refusing to replace unowned command: $PREFIX/bin/bunx"
    return 1
  fi
  if [[ -e "$PREFIX/lib/bun-shim.so" ]] && ! _bun_shim_owned; then
    log_error "Refusing to replace unowned library: $PREFIX/lib/bun-shim.so"
    return 1
  fi
}

_bun_detect_ubuntu_root() {
  local root
  root="$(find /data/data/com.termux -maxdepth 10 -type d \
    -name "rootfs" -path "*/containers/ubuntu/*" 2>/dev/null | head -1)"
  if [ -z "$root" ]; then
    root="$(find /data/data/com.termux -maxdepth 10 -type d \
      -name "ubuntu" -path "*/installed-rootfs/*" 2>/dev/null | head -1)"
  fi
  echo "$root"
}

_bun_proot_ubuntu() {
  proot-distro login --shared-tmp ubuntu -- "$@"
}

_get_latest_bun_version() {
  _get_remote_github_version "$BUN_REPO"
}

_bun_fetch_version() {
  local raw tag
  raw="$(curl -fsSL "https://api.github.com/repos/$BUN_REPO/releases/latest" 2>/dev/null)"
  tag="$(echo "$raw" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
  if [ -z "$tag" ]; then
    raw="$(curl -fsSL "https://api.github.com/repos/$BUN_REPO/tags?per_page=100" 2>/dev/null)"
    tag="$(echo "$raw" | grep '"name":' | sed -E 's/.*"([^"]+)".*/\1/' | sort -V | tail -1)"
  fi
  _parse_version "$tag"
}

_bun_install_deps_native() {
  loading "Installing glibc and dependencies" _bun_install_deps_native_impl
}

_bun_install_deps_native_impl() {
  if [[ ! -f $PREFIX/etc/apt/sources.list.d/glibc.list ]]; then
    if ! pkg install glibc-repo -y &>>"$LOG_FILE"; then
      log_error "Failed to install glibc-repo"
      return 1
    fi
  fi
  if [[ ! -f $PREFIX/glibc/lib/libc.so.6 ]]; then
    if ! pkg install glibc -y &>>"$LOG_FILE"; then
      log_error "Failed to install glibc"
      return 1
    fi
  fi
  declare -A DEPS=(
    ["clang"]="clang-21"
    ["unzip"]="unzip"
    ["curl"]="curl"
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

_download_bun_binary_native() {
  loading "Downloading Bun (glibc)" _download_bun_binary_native_impl
}

_download_bun_binary_native_impl() {
  local version staging_dir old_dir zip_name extracted
  version="$(_bun_fetch_version)"
  if [ -z "$version" ]; then
    log_error "Failed to fetch latest Bun version"
    return 1
  fi
  local arch
  arch="$(uname -m)"
  if [ "$arch" != "aarch64" ] && [ "$arch" != "arm64" ]; then
    log_error "Bun native build only supports aarch64 (got: $arch)"
    return 1
  fi
  mkdir -p "$(dirname "$BUN_DATA_DIR")"
  staging_dir="$(mktemp -d "$(dirname "$BUN_DATA_DIR")/.bun.XXXXXX")" || return 1
  zip_name="bun-linux-aarch64.zip"
  curl -fsSL "https://github.com/$BUN_REPO/releases/download/bun-v$version/$zip_name" \
    -o "$staging_dir/$zip_name" &>>"$LOG_FILE" || {
    rm -rf "$staging_dir"
    log_error "Failed to download Bun binary"
    return 1
  }
  if declare -F github_release_asset_sha256 >/dev/null; then
    expected=$(github_release_asset_sha256 "$BUN_REPO" "bun-v$version" "$zip_name") || expected=""
    if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
      rm -rf "$staging_dir"
      log_error "No published SHA-256 for Bun native; refusing install"
      return 1
    fi
    verify_sha256 "$staging_dir/$zip_name" "$expected" || { rm -rf "$staging_dir"; return 1; }
    if ! safe_extract_zip "$staging_dir/$zip_name" "$staging_dir"; then
      rm -rf "$staging_dir"
      log_error "Failed to extract Bun binary"
      return 1
    fi
  else
    command -v log_warn >/dev/null 2>&1 && log_warn "Integrity helpers unavailable; skipping Bun integrity verification"
    if ! unzip -o "$staging_dir/$zip_name" -d "$staging_dir" &>>"$LOG_FILE"; then
      rm -rf "$staging_dir"
      log_error "Failed to extract Bun binary"
      return 1
    fi
  fi
  rm -f "$staging_dir/$zip_name"
  extracted="$staging_dir/bun-linux-aarch64/bun"
  if [ ! -f "$extracted" ]; then
    rm -rf "$staging_dir"
    log_error "Bun binary not found after extraction"
    return 1
  fi
  if ! mv "$extracted" "$staging_dir/bun.real" || ! rm -rf "$staging_dir/bun-linux-aarch64"; then
    rm -rf "$staging_dir"
    return 1
  fi
  if [ ! -f "$staging_dir/bun.real" ]; then
    rm -rf "$staging_dir"
    log_error "Bun binary not found after extraction"
    return 1
  fi
  chmod +x "$staging_dir/bun.real"
  : >"$staging_dir/.karnel-managed"
  old_dir="${BUN_DATA_DIR}.previous.$$"
  if [[ -e "$BUN_DATA_DIR" ]] && ! mv "$BUN_DATA_DIR" "$old_dir"; then
    rm -rf "$staging_dir"
    return 1
  fi
  if ! mv "$staging_dir" "$BUN_DATA_DIR"; then
    [[ -e "$old_dir" ]] && mv "$old_dir" "$BUN_DATA_DIR"
    return 1
  fi
  rm -rf "$old_dir"
  return 0
}

_compile_bun_helper() {
  loading "Compiling bun helper" _compile_bun_helper_impl
}

_compile_bun_helper_impl() {
	local CC
	if command -v clang-21 &>/dev/null; then
		CC="clang-21"
	elif command -v clang &>/dev/null; then
		CC="clang"
	else
		log_error "C compiler not found (install clang package)"
		return 1
	fi

	local shim_src="$KARNEL_PATH/tools/lang/bun/src/bun-shim.c"
	local wrapper_src="$KARNEL_PATH/tools/lang/bun/src/bun_wrapper.c"
	if [ ! -f "$shim_src" ]; then
		log_error "Shim source not found at $shim_src"
		return 1
	fi
	if [ ! -f "$wrapper_src" ]; then
		log_error "Wrapper source not found at $wrapper_src"
		return 1
	fi
  mkdir -p "$PREFIX/lib" "$PREFIX/bin"
  local shim_tmp wrapper_tmp wrapper_bin_tmp
  shim_tmp="$(mktemp "$PREFIX/lib/.bun-shim.XXXXXX")" || return 1
  if ! $CC -O2 -fPIC -shared -nostdlib -o "$shim_tmp" "$shim_src" &>>"$LOG_FILE"; then
    rm -f "$shim_tmp"
    log_error "Failed to compile bun shim"
    return 1
  fi
  if ! mv -f "$shim_tmp" "$PREFIX/lib/bun-shim.so"; then
    rm -f "$shim_tmp"
    return 1
  fi
  chmod +x "$PREFIX/lib/bun-shim.so"
  wrapper_tmp="$(mktemp "$PREFIX/bin/.bun-wrapper.XXXXXX.c")" || return 1
  wrapper_bin_tmp="$(mktemp "$PREFIX/bin/.bun.XXXXXX")" || { rm -f "$wrapper_tmp"; return 1; }
  sed "s|__BUN_REAL__|$BUN_DATA_DIR/bun.real|g" "$wrapper_src" >"$wrapper_tmp"
  if ! $CC -O2 -o "$wrapper_bin_tmp" "$wrapper_tmp" &>>"$LOG_FILE"; then
    rm -f "$wrapper_tmp" "$wrapper_bin_tmp"
    log_error "Failed to compile bun wrapper"
    return 1
  fi
  if ! mv -f "$wrapper_bin_tmp" "$PREFIX/bin/bun"; then
    rm -f "$wrapper_tmp" "$wrapper_bin_tmp"
    return 1
  fi
  chmod +x "$PREFIX/bin/bun"
  rm -f "$wrapper_tmp"
  sha256sum "$PREFIX/bin/bun" >"$BUN_DATA_DIR/.karnel-wrapper-bun" || return 1
  sha256sum "$PREFIX/lib/bun-shim.so" >"$BUN_DATA_DIR/.karnel-shim" || return 1
  return 0
}

_install_bun_native() {
  _bun_verify_native_ownership || return 1
  _bun_install_deps_native || return 1
  _download_bun_binary_native || return 1
  _compile_bun_helper || return 1
  local bunx_tmp
  bunx_tmp="$PREFIX/bin/.bunx.$$"
  ln -s bun "$bunx_tmp" && mv -f "$bunx_tmp" "$PREFIX/bin/bunx" || { rm -f "$bunx_tmp"; return 1; }
  printf 'bun\n' >"$BUN_DATA_DIR/.karnel-wrapper-bunx"
  log_success "Bun installed natively (glibc build)"
  return 0
}

_install_bun_proot() {
  loading "Installing Bun (proot-distro)" _install_bun_proot_impl
}

_install_bun_proot_impl() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if ! command -v proot-distro &>/dev/null; then
    pkg install proot-distro -y &>>"$LOG_FILE"
  fi
  if [ ! -d "$(_bun_detect_ubuntu_root)" ]; then
    proot-distro install ubuntu:24.04 &>>"$LOG_FILE"
  fi
  local version
  version="$(_bun_fetch_version)"
  if [ -z "$version" ]; then
    log_error "Failed to fetch latest Bun version"
    return 1
  fi
  local download_url="https://github.com/$BUN_REPO/releases/download/bun-v$version/bun-linux-aarch64.zip"
  _bun_proot_ubuntu /bin/bash -c \
    'apt-get update && apt-get upgrade -y && apt-get install -y curl ca-certificates unzip' \
    &>>"$LOG_FILE"
  local expected
  expected=$(github_release_asset_sha256 "$BUN_REPO" "bun-v$version" "bun-linux-aarch64.zip") || expected=""
  if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
    log_error "No published SHA-256 for Bun; refusing install"
    return 1
  fi
  _bun_proot_ubuntu /bin/bash -c '
    export HOME=/root TMPDIR=/tmp
    cd /tmp &&
    curl -fsSL "$1" -o bun.zip &&
    [ "$(sha256sum bun.zip | awk "{print \$1}")" = "$2" ] &&
    unzip -o bun.zip >/dev/null 2>&1 &&
    mkdir -p /usr/local/bin &&
    mv bun-linux-aarch64/bun /usr/local/bin/bun &&
    chmod +x /usr/local/bin/bun &&
    rm -rf bun.zip bun-linux-aarch64
  ' bash "$download_url" "$expected" &>>"$LOG_FILE"
  local ubuntu_root
  ubuntu_root="$(_bun_detect_ubuntu_root)"
  if [ -z "$ubuntu_root" ]; then
    log_error "Ubuntu rootfs not found"
    return 1
  fi
  local bun_bin="$ubuntu_root/usr/local/bin/bun"
  if [ ! -f "$bun_bin" ]; then
    log_error "Bun binary not found after install"
    return 1
  fi
  local wrapper_src="$KARNEL_PATH/tools/lang/bun/bin/bun"
  if [ ! -f "$wrapper_src" ]; then
    log_error "Wrapper template not found at $wrapper_src"
    return 1
  fi
  sed "s|__UBUNTU_ROOTFS__|$ubuntu_root|g" "$wrapper_src" >"$PREFIX/bin/bun"
  chmod +x "$PREFIX/bin/bun"
  mkdir -p "$BUN_DATA_DIR" && : >"$BUN_DATA_DIR/.karnel-proot"
  return 0
}

install_bun() {
  if command -v bun &>/dev/null; then
    log_info "Bun is already installed"
    return 2
  fi
  log_info "Select installation method for Bun:"
  read_select "Installation method" SELECTED_METHOD \
    "Native (recommended) - glibc build with shim" \
    "Proot-distro (alternative) - Ubuntu container"
  case "$SELECTED_METHOD" in
  *Native*)
    _install_bun_native
    ;;
  *Proot-distro*)
    _install_bun_proot
    ;;
  esac
}

_uninstall_bun_native() {
  _bun_wrapper_owned bun && rm -f "$PREFIX/bin/bun"
  _bun_bunx_owned && rm -f "$PREFIX/bin/bunx"
  _bun_shim_owned && rm -f "$PREFIX/lib/bun-shim.so"
  [[ -f "$BUN_DATA_DIR/.karnel-managed" ]] && rm -rf "$BUN_DATA_DIR"
  log_success "Bun (native) uninstalled"
  return 0
}

_uninstall_bun_proot() {
  _bun_proot_ubuntu /bin/bash -c 'rm -f /usr/local/bin/bun' &>>"$LOG_FILE"
  rm -f "$PREFIX/bin/bun" &>>"$LOG_FILE"
  log_success "Bun (proot-distro) uninstalled"
  return 0
}

_uninstall_bun_impl() {
  if [ -f "$BUN_DATA_DIR/bun.real" ] && [ -f "$BUN_DATA_DIR/.karnel-managed" ]; then
    _uninstall_bun_native
    return $?
  fi
  if [ -f "$BUN_DATA_DIR/.karnel-proot" ]; then
    _uninstall_bun_proot
    return $?
  fi
  log_error "Refusing to remove unowned bun command: $PREFIX/bin/bun"
  return 1
}

uninstall_bun() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if [ ! -f "$PREFIX/bin/bun" ]; then
    log_warn "Bun is not installed"
    return 2
  fi
  loading "Uninstalling Bun" _uninstall_bun_impl
}

_update_bun_native() {
  _bun_verify_native_ownership || return 1
  _download_bun_binary_native || return 1
  _compile_bun_helper || return 1
  log_success "Bun (native) updated"
  return 0
}

_update_bun_proot() {
  local version
  version="$(_get_latest_bun_version)"
  if [ -z "$version" ]; then
    log_error "Failed to fetch latest Bun version"
    return 1
  fi
  local download_url="https://github.com/$BUN_REPO/releases/download/bun-v$version/bun-linux-aarch64.zip"
  _bun_proot_ubuntu /bin/bash -c 'rm -f /usr/local/bin/bun' &>>"$LOG_FILE"
  local expected
  expected=$(github_release_asset_sha256 "$BUN_REPO" "bun-v$version" "bun-linux-aarch64.zip") || expected=""
  if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
    log_error "No published SHA-256 for Bun; refusing update"
    return 1
  fi
  _bun_proot_ubuntu /bin/bash -c '
    export HOME=/root TMPDIR=/tmp
    cd /tmp &&
    curl -fsSL "$1" -o bun.zip &&
    [ "$(sha256sum bun.zip | awk "{print \$1}")" = "$2" ] &&
    unzip -o bun.zip >/dev/null 2>&1 &&
    mkdir -p /usr/local/bin &&
    mv bun-linux-aarch64/bun /usr/local/bin/bun &&
    chmod +x /usr/local/bin/bun &&
    rm -rf bun.zip bun-linux-aarch64
  ' bash "$download_url" "$expected" &>>"$LOG_FILE"
  local ubuntu_root
  ubuntu_root="$(_bun_detect_ubuntu_root)"
  local bun_bin="$ubuntu_root/usr/local/bin/bun"
  if [ ! -f "$bun_bin" ]; then
    log_error "Bun binary not found after update"
    return 1
  fi
  log_success "Bun (proot-distro) updated"
  return 0
}

_do_update_bun() {
  mkdir -p "$(dirname "$LOG_FILE")"
  if [ -f "$BUN_DATA_DIR/bun.real" ]; then
    _update_bun_native
    return $?
  fi
  loading "Updating Bun (proot-distro)" _update_bun_proot
}

update_bun() {
  _check_update_needed "Bun" "$(_get_installed_version bun)" "$(_get_latest_bun_version)" _do_update_bun
}

reinstall_bun() {
  uninstall_bun
  install_bun
}
