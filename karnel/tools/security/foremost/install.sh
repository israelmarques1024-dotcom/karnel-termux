#!/usr/bin/env bash

_TOOL="foremost"
_PKG="foremost"

install_foremost() {
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

uninstall_foremost() {
  log_info "Removendo $_TOOL..."
  if pkg uninstall -y "$_PKG" 2>/dev/null || apt remove -y "$_PKG" 2>/dev/null; then
    log_success "$_TOOL removido"
    return 0
  fi
  log_error "Falha ao remover $_TOOL"
  return 1
}

update_foremost() {
  log_info "Atualizando foremost..."
  if pkg install -y foremost 2>/dev/null || apt install -y foremost 2>/dev/null; then
    log_success "foremost atualizado"
    return 0
  fi
  log_error "Falha ao atualizar foremost"
  return 1
}

reinstall_foremost() {
  uninstall_foremost || [[ $? -eq 2 ]] || return 1

  install_foremost
}
