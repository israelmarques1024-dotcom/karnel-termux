#!/usr/bin/env bash

# Kimchi CLI - Karnel installer
# Usa o sistema de import padronizado do Karnel (bootstrap.sh)
import "@/utils/log"
import "@/utils/colors"

export KARNEL_CACHE="${KARNEL_CACHE:-$HOME/.cache/karnel}"
export PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

LOG_FILE="$KARNEL_CACHE/install_ai.log"
KIMCHI_DATA_DIR="$HOME/.local/share/karnel-data/kimchi"
KIMCHI_BIN_PATH="$KIMCHI_DATA_DIR/kimchi"

_get_latest_kimchi_version() {
  curl -fsSL https://api.github.com/repos/getkimchi/kimchi/releases/latest 2>/dev/null |
    grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

_kimchi_download_binary() {
  loading "Downloading Kimchi CLI" _kimchi_download_binary_impl
}

_kimchi_download_binary_impl() {
  local latest_version
  latest_version=$(_get_latest_kimchi_version)
  if [ -z "$latest_version" ]; then
    log_error "Failed to fetch latest Kimchi version"
    return 1
  fi

  mkdir -p "$KIMCHI_DATA_DIR"

  local arch
  arch=$(uname -m)
  local kimchi_arch=""
  case "$arch" in
    aarch64|arm64) kimchi_arch="arm64" ;;
    x86_64) kimchi_arch="amd64" ;;
    *) kimchi_arch="arm64" ;;
  esac

  local tarball="kimchi_linux_${kimchi_arch}.tar.gz"
  local download_url="https://github.com/getkimchi/kimchi/releases/download/${latest_version}/${tarball}"

  if ! curl -fsSL "$download_url" -o "$KIMCHI_DATA_DIR/$tarball" &>>"$LOG_FILE"; then
    log_error "Failed to download Kimchi binary"
    return 1
  fi

  if ! tar -zxf "$KIMCHI_DATA_DIR/$tarball" -C "$KIMCHI_DATA_DIR" &>>"$LOG_FILE"; then
    log_error "Failed to extract Kimchi binary"
    return 1
  fi

  rm -f "$KIMCHI_DATA_DIR/$tarball"

  # Find the kimchi binary (may be named kimchi or kimchi-linux-*)
  local kimchi_bin=""
  if [ -f "$KIMCHI_BIN_PATH" ]; then
    kimchi_bin="$KIMCHI_BIN_PATH"
  else
    kimchi_bin=$(find "$KIMCHI_DATA_DIR" -name "kimchi*" -type f -executable 2>/dev/null | head -1)
  fi

  if [ -z "$kimchi_bin" ] || [ ! -f "$kimchi_bin" ]; then
    log_error "Kimchi binary not found after extraction"
    return 1
  fi

  # Rename if needed
  if [ "$kimchi_bin" != "$KIMCHI_BIN_PATH" ]; then
    mv "$kimchi_bin" "$KIMCHI_BIN_PATH"
  fi

  chmod +x "$KIMCHI_BIN_PATH"

  # Validacao: confirma que o binario existe e e executavel
  if [ ! -x "$KIMCHI_BIN_PATH" ]; then
    log_error "Kimchi binary is not executable after setup"
    return 1
  fi

  return 0
}

_install_kimchi_wrapper() {
  loading "Creating Kimchi wrapper" _install_kimchi_wrapper_impl
}

_install_kimchi_wrapper_impl() {
  local wrapper_path="$PREFIX/bin/kimchi"

  # Cria wrapper com CAMINHO ABSOLUTO para evitar depender de variaveis em runtime.
  # O caminho e resolvido no momento da instalacao (KIMCHI_BIN_PATH = $HOME/.local/share/karnel-data/kimchi/kimchi).
  cat > "$wrapper_path" << WRAPPER
#!/data/data/com.termux/files/usr/bin/bash
# Kimchi CLI wrapper — gerado pelo Karnel
# Caminho absoluto do binario (resolvido na instalacao)
KIMCHI_BIN="${KIMCHI_BIN_PATH}"

if [ "\$#" -eq 0 ]; then
  exec "\$KIMCHI_BIN"
elif [ "\$1" = "-i" ] || [ "\$1" = "--interactive" ]; then
  # Kimchi nao tem flag -i; modo interativo e o padrao
  exec "\$KIMCHI_BIN"
else
  exec "\$KIMCHI_BIN" "\$@"
fi
WRAPPER
  chmod +x "$wrapper_path"

  # Valida que o wrapper foi criado corretamente
  if [ ! -f "$wrapper_path" ]; then
    log_error "Failed to create kimchi wrapper at $wrapper_path"
    return 1
  fi

  # Verifica se o caminho no wrapper esta correto (nao pode ser "/kimchi" na raiz)
  if grep -q 'KIMCHI_BIN="/kimchi"' "$wrapper_path" 2>/dev/null; then
    log_error "Kimchi wrapper has invalid path (/kimchi) — KIMCHI_DATA_DIR was empty"
    rm -f "$wrapper_path"
    return 1
  fi

  # Kimchi é glibc — precisa rodar dentro do proot ubuntu no Termux
  if ! command -v proot-distro &>/dev/null; then
    pkg install proot-distro -y &>>"$LOG_FILE" || true
  fi

  # Rewrite wrapper to use proot-distro
  cat > "$wrapper_path" << 'PROOT_WRAPPER'
#!/data/data/com.termux/files/usr/bin/bash
KIMCHI_DIR="/data/data/com.termux/files/home/.local/share/karnel-data/kimchi"
KIMCHI_BIN="$KIMCHI_DIR/kimchi"

ARGS=""
for arg in "$@"; do
  ARGS="$ARGS '$arg'"
done

exec proot-distro login ubuntu -- bash -c "
  export HOME=/root
  mkdir -p /root/.local/share/kimchi
  cp -r $KIMCHI_DIR/share/kimchi/* /root/.local/share/kimchi/ 2>/dev/null || true
  $KIMCHI_BIN $ARGS
" 2>&1
PROOT_WRAPPER
  chmod +x "$wrapper_path"

  return 0
}

install_kimchi_code() {
  # Verificacao dupla: binario REAL (nao wrapper) + comando no PATH
  if [ -f "$KIMCHI_BIN_PATH" ] && command -v kimchi &>/dev/null; then
    log_info "Kimchi is already installed"
    return 2
  fi

  log_info "Installing Kimchi CLI..."

  mkdir -p "$(dirname "$LOG_FILE")" "$KIMCHI_DATA_DIR"

  _kimchi_download_binary || return 1
  _install_kimchi_wrapper || return 1

  # Validacao final: command -v + verificacao de que nao e stub
  if command -v kimchi &>/dev/null; then
    local bin_path
    bin_path=$(command -v kimchi)
    if [ -f "$bin_path" ] && grep -q "KIMCHI_BIN=" "$bin_path" 2>/dev/null; then
      log_success "Kimchi CLI installed"
      log_info "Usage: ${D_CYAN}kimchi${NC} to launch the interactive TUI"
      log_info "Setup: ${D_CYAN}kimchi setup${NC} for first-time configuration"
      log_info "Docs:  ${D_CYAN}https://docs.kimchi.dev${NC}"
      return 0
    fi
  fi

  log_error "Kimchi CLI installation failed: binary not found or invalid"
  rm -f "$PREFIX/bin/kimchi" 2>/dev/null
  return 1
}

uninstall_kimchi_code() {
  log_info "Uninstalling Kimchi CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  rm -f "$PREFIX/bin/kimchi" 2>/dev/null
  rm -rf "$KIMCHI_DATA_DIR" 2>/dev/null

  log_success "Kimchi CLI uninstalled"
  return 0
}

update_kimchi_code() {
  log_info "Updating Kimchi CLI..."
  mkdir -p "$(dirname "$LOG_FILE")"

  rm -rf "$KIMCHI_DATA_DIR" 2>/dev/null
  mkdir -p "$KIMCHI_DATA_DIR"

  _kimchi_download_binary || {
    log_error "Failed to update Kimchi CLI"
    return 1
  }

  _install_kimchi_wrapper || {
    log_error "Failed to update Kimchi CLI wrapper"
    return 1
  }

  log_success "Kimchi CLI updated"
  return 0
}

reinstall_kimchi_code() {
  uninstall_kimchi_code
  install_kimchi_code
}
