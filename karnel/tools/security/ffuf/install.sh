#!/usr/bin/env bash

inc_ffuf_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    aarch64) echo "arm64" ;;
    armv7l|arm) echo "arm" ;;
    x86_64) echo "amd64" ;;
    *) echo ""; return 1 ;;
  esac
}

_download_ffuf() {
  local version arch url
  version=$(curl -fsSL "https://api.github.com/repos/ffuf/ffuf/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  [ -z "$version" ] && version="v2.1.0"
  arch=$(inc_ffuf_arch) || return 1
  url="https://github.com/ffuf/ffuf/releases/download/${version}/ffuf_${version}_linux_${arch}.tar.gz"
  curl -fsSL "$url" -o /tmp/ffuf.tar.gz || return 1
  tar -zxf /tmp/ffuf.tar.gz -C /tmp ffuf 2>/dev/null || tar -zxf /tmp/ffuf.tar.gz -C /tmp 2>/dev/null
  mv /tmp/ffuf "$PREFIX/bin/ffuf" 2>/dev/null
  chmod +x "$PREFIX/bin/ffuf" 2>/dev/null
  rm -f /tmp/ffuf.tar.gz
  return 0
}

install_ffuf() {
  if command -v ffuf &>/dev/null; then
    log_info "ffuf já está instalado"
    return 2
  fi
  log_info "Instalando ffuf..."
  if pkg install -y ffuf 2>/dev/null || apt install -y ffuf 2>/dev/null; then
    log_success "ffuf instalado"
    return 0
  fi
  if _download_ffuf; then
    log_success "ffuf instalado"
    return 0
  fi
  log_error "Falha ao instalar ffuf"
  return 1
}

uninstall_ffuf() {
  log_info "Removendo ffuf..."
  rm -f "$PREFIX/bin/ffuf"
  log_success "ffuf removido"
}

update_ffuf() {
  uninstall_ffuf
  install_ffuf
}

reinstall_ffuf() {
  uninstall_ffuf
  install_ffuf
}
