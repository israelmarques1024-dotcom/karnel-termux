#!/usr/bin/env bash

_TOOL="nmap"
_PKG="nmap"

install_nmap() {
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

uninstall_nmap() {
  log_info "Removendo $_TOOL..."
  if pkg uninstall -y "$_PKG" 2>/dev/null || apt remove -y "$_PKG" 2>/dev/null; then
    log_success "$_TOOL removido"
    return 0
  fi
  log_error "Falha ao remover $_TOOL"
  return 1
}

update_nmap() {
  log_info "Atualizando nmap..."
  if pkg install -y nmap 2>/dev/null || apt install -y nmap 2>/dev/null; then
    log_success "nmap atualizado"
    return 0
  fi
  log_error "Falha ao atualizar nmap"
  return 1
}

reinstall_nmap() {
  uninstall_nmap || [[ $? -eq 2 ]] || return 1

  install_nmap
}
