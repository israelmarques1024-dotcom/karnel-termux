#!/usr/bin/env bash

_GOBUSTER_VERSION="3.6"
_GOBUSTER_DIR="$PREFIX/share/gobuster"

_install_gobuster_bin() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    aarch64) _GOBUSTER_ARCH="arm64" ;;
    armv7l|arm) _GOBUSTER_ARCH="arm" ;;
    x86_64) _GOBUSTER_ARCH="amd64" ;;
    *) log_error "Arquitetura não suportada: $arch"; return 1 ;;
  esac
  local url="https://github.com/OJ/gobuster/releases/download/v${_GOBUSTER_VERSION}/gobuster_Linux-${_GOBUSTER_ARCH}.tar.gz"
  mkdir -p "$_GOBUSTER_DIR"
  curl -fsSL "$url" -o /tmp/gobuster.tar.gz || return 1
  tar -zxf /tmp/gobuster.tar.gz -C "$_GOBUSTER_DIR" || return 1
  rm -f /tmp/gobuster.tar.gz
  mv "$_GOBUSTER_DIR/gobuster" "$PREFIX/bin/gobuster"
  chmod +x "$PREFIX/bin/gobuster"
  rm -rf "$_GOBUSTER_DIR"
  return 0
}

install_gobuster() {
  if command -v gobuster &>/dev/null; then
    log_info "gobuster já está instalado"
    return 2
  fi
  log_info "Instalando gobuster..."
  if pkg install -y gobuster 2>/dev/null || apt install -y gobuster 2>/dev/null; then
    log_success "gobuster instalado"
    return 0
  fi
  if _install_gobuster_bin; then
    log_success "gobuster instalado"
    return 0
  fi
  log_error "Falha ao instalar gobuster"
  return 1
}

uninstall_gobuster() {
  log_info "Removendo gobuster..."
  rm -f "$PREFIX/bin/gobuster"
  log_success "gobuster removido"
}

update_gobuster() {
  log_info "gobuster atualizado via download"
  uninstall_gobuster
  install_gobuster
}

reinstall_gobuster() {
  uninstall_gobuster
  install_gobuster
}
