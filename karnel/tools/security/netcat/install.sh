#!/usr/bin/env bash

_TOOL="nc"
_PKG="netcat-openbsd"

install_netcat() {
  if command -v "$_TOOL" &>/dev/null; then
    log_info "$_TOOL já está instalado"
    return 2
  fi
  log_info "Instalando netcat..."
  if pkg install -y "$_PKG" 2>/dev/null || apt install -y "$_PKG" 2>/dev/null; then
    log_success "netcat instalado"
    return 0
  fi
  log_error "Falha ao instalar netcat"
  return 1
}

uninstall_netcat() {
  log_info "Removendo netcat..."
  pkg uninstall -y "$_PKG" 2>/dev/null || true
  log_success "netcat removido"
}

update_netcat() {
  log_info "netcat atualizado via gerenciador de pacotes"
  return 2
}

reinstall_netcat() {
  uninstall_netcat
  install_netcat
}
