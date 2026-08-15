#!/usr/bin/env bash

# Kimchi CLI - Karnel installer
# Usa o sistema de import padronizado do Karnel (bootstrap.sh)
import "@/utils/log"
import "@/utils/version"
import "@/utils/colors"
import "@/utils/install"

export KARNEL_CACHE="${KARNEL_CACHE:-$HOME/.cache/karnel}"
export PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
KIMCHI_DATA_DIR="$HOME/.local/share/karnel-data/kimchi"
KIMCHI_BIN_PATH="$KIMCHI_DATA_DIR/kimchi"
KIMCHI_MARKER=".karnel-managed"
KIMCHI_WRAPPER_MARKER="$KIMCHI_DATA_DIR/.karnel-wrapper"

_get_latest_kimchi_version() {
  curl -fsSL https://api.github.com/repos/getkimchi/kimchi/releases/latest 2>/dev/null |
    grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

_kimchi_download_binary() {
  loading "Downloading Kimchi CLI" _kimchi_download_binary_impl
}

_kimchi_download_binary_impl() {
  local latest_version staging_dir expected actual
  latest_version=$(_get_latest_kimchi_version)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Kimchi version"
    return 1
  fi

  local arch
  arch=$(uname -m)
  local kimchi_arch=""
  case "$arch" in
    aarch64|arm64) kimchi_arch="arm64" ;;
    x86_64) kimchi_arch="amd64" ;;
    *) log_error "Unsupported Kimchi architecture: $arch"; return 1 ;;
  esac

  local tarball="kimchi_linux_${kimchi_arch}.tar.gz"
  local download_url="https://github.com/getkimchi/kimchi/releases/download/${latest_version}/${tarball}"
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

  # Find the kimchi binary (may be named kimchi or kimchi-linux-*)
  local kimchi_bin=""
  if [ -f "$staging_dir/kimchi" ]; then
    kimchi_bin="$staging_dir/kimchi"
  else
    kimchi_bin=$(find "$staging_dir" -name "kimchi*" -type f -executable 2>/dev/null | head -1)
  fi

  if [ -z "$kimchi_bin" ] || [ ! -f "$kimchi_bin" ]; then
    log_error "Kimchi binary not found after extraction"
    return 1
  fi

  # Rename if needed
  if [ "$kimchi_bin" != "$staging_dir/kimchi" ]; then
    mv "$kimchi_bin" "$staging_dir/kimchi"
  fi

  chmod +x "$staging_dir/kimchi"

  # Validacao: confirma que o binario existe e e executavel
  if [ ! -x "$staging_dir/kimchi" ]; then
    log_error "Kimchi binary is not executable after setup"
    return 1
  fi

  replace_managed_directory "$staging_dir" "$KIMCHI_DATA_DIR" "$KIMCHI_MARKER"
}

_install_kimchi_wrapper() {
  loading "Creating Kimchi wrapper" _install_kimchi_wrapper_impl
}

_install_kimchi_wrapper_impl() {
  local wrapper_path="$PREFIX/bin/kimchi"
  local staged_wrapper

  # Kimchi é glibc — precisa rodar dentro do proot ubuntu no Termux
  if ! command -v proot-distro &>/dev/null; then
    pkg install proot-distro -y &>>"$LOG_FILE" || true
  fi

  staged_wrapper=$(mktemp "$PREFIX/bin/.kimchi.XXXXXX") || return 1
  cat > "$staged_wrapper" << PROOT_WRAPPER
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login ubuntu -- env HOME=/root "$KIMCHI_BIN_PATH" "\$@"
PROOT_WRAPPER
  chmod +x "$staged_wrapper"
  mv "$staged_wrapper" "$wrapper_path" || return 1
  record_managed_file "$wrapper_path" "$KIMCHI_WRAPPER_MARKER"
}

install_kimchi_code() {
  # Verificacao dupla: binario REAL (nao wrapper) + comando no PATH
  if [ -f "$KIMCHI_BIN_PATH" ] && command -v kimchi &>/dev/null; then
    log_info "Kimchi is already installed"
    return 2
  fi
  if [ -e "$PREFIX/bin/kimchi" ]; then
    log_error "Refusing to replace an existing Kimchi wrapper not owned by Karnel"
    return 1
  fi

  log_info "Installing Kimchi CLI..."

  mkdir -p "$(dirname "$LOG_FILE")"

  _kimchi_download_binary || return 1
  _install_kimchi_wrapper || return 1

  if managed_file_matches "$PREFIX/bin/kimchi" "$KIMCHI_WRAPPER_MARKER"; then
    log_success "Kimchi CLI installed"
    log_info "Usage: ${D_CYAN}kimchi${NC} to launch the interactive TUI"
    log_info "Setup: ${D_CYAN}kimchi setup${NC} for first-time configuration"
    log_info "Docs:  ${D_CYAN}https://docs.kimchi.dev${NC}"
    return 0
  fi

  log_error "Kimchi CLI installation failed: binary not found or invalid"
  managed_file_matches "$PREFIX/bin/kimchi" "$KIMCHI_WRAPPER_MARKER" && rm -f "$PREFIX/bin/kimchi"
  return 1
}

uninstall_kimchi_code() {
  log_info "Uninstalling Kimchi CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  if ! managed_file_matches "$PREFIX/bin/kimchi" "$KIMCHI_WRAPPER_MARKER" || [ ! -f "$KIMCHI_DATA_DIR/$KIMCHI_MARKER" ]; then
    log_error "Refusing to remove a Kimchi installation not owned by Karnel"
    return 1
  fi
  rm -f "$PREFIX/bin/kimchi"
  rm -rf "$KIMCHI_DATA_DIR"

  log_success "Kimchi CLI uninstalled"
  return 0
}

update_kimchi_code() {
  _check_update_needed "Kimchi CLI" "$(_get_installed_version kimchi)" "$(_get_remote_github_version getkimchi/kimchi)" _do_update_kimchi_code
}

_do_update_kimchi_code() {
  _kimchi_download_binary || {
    log_error "Failed to update Kimchi CLI"
    return 1
  }

  _install_kimchi_wrapper || {
    log_error "Failed to update Kimchi CLI wrapper"
    return 1
  }

  return 0
}

reinstall_kimchi_code() {
  if command -v kimchi &>/dev/null; then
    _do_update_kimchi_code
  else
    install_kimchi_code
  fi
}
