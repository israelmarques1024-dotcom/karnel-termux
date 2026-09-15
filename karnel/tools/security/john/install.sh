#!/usr/bin/env bash

_TOOL="john"
_PKG="john"

install_john() {
  if command -v "$_TOOL" &>/dev/null; then
    log_info "$_TOOL já está instalado"
    return 2
  fi
  log_info "Instalando $_TOOL..."
  if pkg install -y "$_PKG" 2>/dev/null || apt install -y "$_PKG" 2>/dev/null; then
    log_success "$_TOOL instalado"
    return 0
  fi
  log_error "Falha ao instalar $_TOOL"
  return 1
}

uninstall_john() {
  log_info "Removendo $_TOOL..."
  if pkg uninstall -y "$_PKG" 2>/dev/null || apt remove -y "$_PKG" 2>/dev/null; then
    log_success "$_TOOL removido"
    return 0
  fi
  log_error "Falha ao remover $_TOOL"
  return 1
}

update_john() {
  log_info "Atualizando john..."
  if pkg install -y john 2>/dev/null || apt install -y john 2>/dev/null; then
    log_success "john atualizado"
    return 0
  fi
  log_error "Falha ao atualizar john"
  return 1
}

reinstall_john() {
  uninstall_john
  install_john
}
