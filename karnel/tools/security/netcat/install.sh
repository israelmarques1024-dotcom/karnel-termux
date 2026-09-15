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
  log_info "Removendo $_TOOL..."
  if pkg uninstall -y "$_PKG" 2>/dev/null || apt remove -y "$_PKG" 2>/dev/null; then
    log_success "$_TOOL removido"
    return 0
  fi
  log_error "Falha ao remover $_TOOL"
  return 1
}

update_netcat() {
  log_info "Atualizando netcat..."
  if pkg install -y netcat-openbsd 2>/dev/null || apt install -y netcat-openbsd 2>/dev/null; then
    log_success "netcat atualizado"
    return 0
  fi
  log_error "Falha ao atualizar netcat"
  return 1
}

reinstall_netcat() {
  uninstall_netcat
  install_netcat
}
