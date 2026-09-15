#!/usr/bin/env bash

_TOOL="smbclient"
_PKG="smbclient"

install_smbclient() {
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

uninstall_smbclient() {
  log_info "Removendo $_TOOL..."
  if pkg uninstall -y "$_PKG" 2>/dev/null || apt remove -y "$_PKG" 2>/dev/null; then
    log_success "$_TOOL removido"
    return 0
  fi
  log_error "Falha ao remover $_TOOL"
  return 1
}

update_smbclient() {
  log_info "Atualizando smbclient..."
  if pkg install -y smbclient 2>/dev/null || apt install -y smbclient 2>/dev/null; then
    log_success "smbclient atualizado"
    return 0
  fi
  log_error "Falha ao atualizar smbclient"
  return 1
}

reinstall_smbclient() {
  uninstall_smbclient || [[ $? -eq 2 ]] || return 1

  install_smbclient
}
