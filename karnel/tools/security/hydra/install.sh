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
  pkg uninstall -y "$_PKG" 2>/dev/null || true
  log_success "$_TOOL removido"
}

update_hydra() {
  log_info "$_TOOL atualizado via gerenciador de pacotes"
  return 2
}

reinstall_hydra() {
  uninstall_hydra
  install_hydra
}
