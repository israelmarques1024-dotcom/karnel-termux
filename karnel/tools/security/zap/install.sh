#!/usr/bin/env bash

_ZAP_DIR="$PREFIX/share/zap"
_ZAP_VERSION="2.16.1"

install_zap() {
  if command -v zap &>/dev/null; then
    log_info "zap já está instalado"
    return 2
  fi
  log_info "Instalando ZAP (Zed Attack Proxy)..."

  if pkg install -y zaproxy 2>/dev/null || apt install -y zaproxy 2>/dev/null; then
    log_success "zap instalado"
    return 0
  fi

  pkg install -y curl openjdk-17 2>/dev/null

  mkdir -p "$_ZAP_DIR"

  local arch
  arch="$(uname -m)"
  case "$arch" in
    aarch64|armv7l|arm) ZAP_ASSET="ZAP_${_ZAP_VERSION}-Linux.tar.gz" ;;
    x86_64) ZAP_ASSET="ZAP_${_ZAP_VERSION}-Linux-x64.tar.gz" ;;
    *) log_error "Arquitetura não suportada: $arch"; return 1 ;;
  esac

  local url="https://github.com/zaproxy/zaproxy/releases/download/v${_ZAP_VERSION}/$ZAP_ASSET"

  curl -fsSL "$url" -o /tmp/zap.tar.gz 2>/dev/null || {
    log_error "Falha ao baixar ZAP"
    return 1
  }

  tar -zxf /tmp/zap.tar.gz -C "$_ZAP_DIR" 2>/dev/null
  rm -f /tmp/zap.tar.gz

  local zap_home
  zap_home=$(find "$_ZAP_DIR" -maxdepth 1 -type d -name "ZAP*" | head -1)

  if [ -n "$zap_home" ]; then
    cat > "$PREFIX/bin/zap" << 'SCRIPT'
#!/usr/bin/env bash
ZAP_HOME=$(find "$PREFIX/share/zap" -maxdepth 1 -type d -name "ZAP*" | head -1)
exec "$ZAP_HOME/zap.sh" "$@"
SCRIPT
    chmod +x "$PREFIX/bin/zap"
    log_success "zap instalado"
    return 0
  fi

  log_error "Falha ao instalar ZAP"
  return 1
}

uninstall_zap() {
  log_info "Removendo ZAP..."
  rm -f "$PREFIX/bin/zap"
  rm -rf "$_ZAP_DIR"
  log_success "zap removido"
}

update_zap() {
  uninstall_zap
  install_zap
}

reinstall_zap() {
  uninstall_zap
  install_zap
}
