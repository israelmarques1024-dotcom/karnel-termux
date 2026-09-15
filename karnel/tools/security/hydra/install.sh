#!/usr/bin/env bash

_TOOL="hydra"
_PKG="thc-hydra"

install_hydra() {
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

uninstall_hydra() {
  log_info "Removendo $_TOOL..."
  if pkg uninstall -y "$_PKG" 2>/dev/null || apt remove -y "$_PKG" 2>/dev/null; then
    log_success "$_TOOL removido"
    return 0
  fi
  log_error "Falha ao remover $_TOOL"
  return 1
}

update_hydra() {
  log_info "Atualizando hydra..."
  if pkg install -y thc-hydra 2>/dev/null || apt install -y thc-hydra 2>/dev/null; then
    log_success "hydra atualizado"
    return 0
  fi
  log_error "Falha ao atualizar hydra"
  return 1
}

reinstall_hydra() {
  uninstall_hydra || [[ $? -eq 2 ]] || return 1

  install_hydra
}
