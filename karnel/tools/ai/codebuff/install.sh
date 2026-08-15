#!/usr/bin/env bash

import "@/utils/log"
import "@/utils/colors"
import "@/utils/version"
import "@/utils/install"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
CODEBUFF_DATA_DIR="$HOME/.local/share/karnel-data/codebuff"
CODEBUFF_MARKER=".karnel-managed"
CODEBUFF_WRAPPER_MARKER="$CODEBUFF_DATA_DIR/.karnel-wrapper"

_codebuff_detect_ubuntu_root() {
  local root
  root="$(find /data/data/com.termux -maxdepth 10 -type d \
    -name "rootfs" -path "*/containers/ubuntu/*" 2>/dev/null | head -1)"

  if [ -z "$root" ]; then
    root="$(find /data/data/com.termux -maxdepth 10 -type d \
      -name "ubuntu" -path "*/installed-rootfs/*" 2>/dev/null | head -1)"
  fi

  echo "$root"
}

_codebuff_proot_ubuntu() {
  proot-distro login \
    --shared-tmp \
    ubuntu \
    -- "$@"
}

_get_latest_codebuff_version() {
  curl -fsSL 'https://api.github.com/repos/CodebuffAI/codebuff-community/releases?per_page=20' |
    sed -n 's/.*"tag_name": "v\([0-9][0-9.]*\)".*/\1/p' | head -1
}

_codebuff_install_deps_native() {
  loading "Installing glibc and dependencies" _codebuff_install_deps_native_impl
}

_codebuff_install_deps_native_impl() {
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
    ["git"]="git"
    ["curl"]="curl"
    ["tar"]="tar"
    ["clang"]="cc"
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

_download_codebuff_binary() {
  loading "Downloading Codebuff" _download_codebuff_binary_impl
}

_download_codebuff_binary_impl() {
  local latest_version staging_dir tarball download_url
  case "$(uname -m)" in
    aarch64|arm64) ;;
    *) log_error "Codebuff Linux ARM64 asset is unavailable for architecture: $(uname -m)"; return 1 ;;
  esac
  latest_version=$(_get_latest_codebuff_version)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Codebuff version"
    return 1
  fi

  mkdir -p "$(dirname "$CODEBUFF_DATA_DIR")"
  staging_dir=$(mktemp -d "$(dirname "$CODEBUFF_DATA_DIR")/.codebuff.XXXXXX") || return 1
  tarball="codebuff-linux-arm64.tar.gz"
  download_url="https://github.com/CodebuffAI/codebuff-community/releases/download/v${latest_version}/${tarball}"

  if ! curl -fsSL "$download_url" -o "$staging_dir/$tarball" &>>"$LOG_FILE"; then
    rm -rf "$staging_dir"
    log_error "Failed to download Codebuff binary"
    return 1
  fi

  if ! verify_github_release_asset CodebuffAI/codebuff-community "v${latest_version}" "$tarball" "$staging_dir/$tarball" ||
    ! extract_tarball "$staging_dir/$tarball" "$staging_dir"; then
    rm -rf "$staging_dir"
    return 1
  fi

  if [ ! -f "$staging_dir/codebuff" ]; then
    rm -rf "$staging_dir"
    log_error "Codebuff binary not found after extraction"
    return 1
  fi

  chmod +x "$staging_dir/codebuff"
  replace_managed_directory "$staging_dir" "$CODEBUFF_DATA_DIR" "$CODEBUFF_MARKER"
}

_compile_codebuff_helper() {
  loading "Compiling helper" _compile_codebuff_helper_impl
}

_compile_codebuff_helper_impl() {
  local HELPER_SRC="$KARNEL_PATH/tools/ai/codebuff/helper/codebuff_helper.c"
  if [ ! -f "$HELPER_SRC" ]; then
    log_error "Helper source not found at $HELPER_SRC"
    return 1
  fi

  local staged_wrapper
  staged_wrapper=$(mktemp "$PREFIX/bin/.codebuff.XXXXXX") || return 1
  if ! cc -O2 -o "$staged_wrapper" "$HELPER_SRC" &>>"$LOG_FILE"; then
    rm -f "$staged_wrapper"
    log_error "Failed to compile codebuff helper"
    return 1
  fi

  chmod +x "$staged_wrapper"
  mv "$staged_wrapper" "$PREFIX/bin/codebuff" || return 1
  record_managed_file "$PREFIX/bin/codebuff" "$CODEBUFF_WRAPPER_MARKER"
}

_install_codebuff_native() {
  _codebuff_install_deps_native || return 1
  _download_codebuff_binary || return 1
  _compile_codebuff_helper || return 1
  log_success "Codebuff installed natively"
  return 0
}

_install_codebuff_proot() {
  loading "Installing Codebuff (proot-distro)" _install_codebuff_proot_impl
}

_install_codebuff_proot_impl() {
  case "$(uname -m)" in
    aarch64|arm64) ;;
    *) log_error "Codebuff Linux ARM64 asset is unavailable for architecture: $(uname -m)"; return 1 ;;
  esac
  log_error "Codebuff Proot install is disabled because upstream provides no authenticated Proot installer; use native mode"
  return 1
}

install_codebuff() {
  if command -v codebuff &>/dev/null; then
    log_info "Codebuff is already installed"
    return 2
  fi
  if [ -e "$PREFIX/bin/codebuff" ]; then
    log_error "Refusing to replace an existing Codebuff wrapper not owned by Karnel"
    return 1
  fi

  log_info "Installing Codebuff..."

  if [[ -t 0 ]] && [[ -t 1 ]]; then
    log_info "Select installation method for Codebuff:"
    read_select "Installation method" SELECTED_METHOD \
      "Native (recommended) - Compile with glibc support" \
      "Proot-distro (alternative) - Ubuntu container"

    case "$SELECTED_METHOD" in
    *Native*)
      _install_codebuff_native
      ;;
    *Proot-distro*)
      _install_codebuff_proot
      ;;
    esac
  else
    _install_codebuff_native
  fi
}

uninstall_codebuff() {
  log_info "Uninstalling Codebuff..."
  mkdir -p "$(dirname "$LOG_FILE")"

  if [ ! -f "$PREFIX/bin/codebuff" ]; then
    log_warn "Codebuff is not installed"
    return 1
  fi

  if [ -f "$CODEBUFF_DATA_DIR/$CODEBUFF_MARKER" ] && managed_file_matches "$PREFIX/bin/codebuff" "$CODEBUFF_WRAPPER_MARKER"; then
    rm -f "$PREFIX/bin/codebuff"
    rm -rf "$CODEBUFF_DATA_DIR"
    log_success "Codebuff (native) uninstalled"
    return 0
  fi

  log_error "Refusing to remove a Codebuff installation not owned by Karnel"
  return 1
}

update_codebuff() {
  _check_update_needed "Codebuff" "$(_get_installed_version codebuff)" "$(_get_remote_github_version CodebuffAI/codebuff-community)" _update_codebuff_impl
}

_update_codebuff_impl() {
  if [ -f "$CODEBUFF_DATA_DIR/codebuff" ]; then
    _install_codebuff_native
    return $?
  fi

  log_error "Refusing to remove a Codebuff installation not owned by Karnel"
  return 1
}

reinstall_codebuff() {
  if command -v codebuff &>/dev/null; then
    _update_codebuff_impl
  else
    install_codebuff
  fi
}
