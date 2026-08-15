#!/usr/bin/env bash

_TOOL="binwalk"
_PKG="binwalk"

install_binwalk() {
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

uninstall_binwalk() {
  log_info "Removendo $_TOOL..."
  pkg uninstall -y "$_PKG" 2>/dev/null || true
  log_success "$_TOOL removido"
}

update_binwalk() {
  log_info "Atualizando binwalk..."
  if pkg install -y binwalk 2>/dev/null || apt install -y binwalk 2>/dev/null; then
    log_success "binwalk atualizado"
    return 0
  fi
  log_error "Falha ao atualizar binwalk"
  return 1
}

reinstall_binwalk() {
  uninstall_binwalk
  install_binwalk
}
