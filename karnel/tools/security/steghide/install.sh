#!/usr/bin/env bash

_TOOL="steghide"
_PKG="steghide"

install_steghide() {
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

uninstall_steghide() {
  log_info "Removendo $_TOOL..."
  pkg uninstall -y "$_PKG" 2>/dev/null || true
  log_success "$_TOOL removido"
}

update_steghide() {
  log_info "Atualizando steghide..."
  if pkg install -y steghide 2>/dev/null || apt install -y steghide 2>/dev/null; then
    log_success "steghide atualizado"
    return 0
  fi
  log_error "Falha ao atualizar steghide"
  return 1
}

reinstall_steghide() {
  uninstall_steghide
  install_steghide
}
