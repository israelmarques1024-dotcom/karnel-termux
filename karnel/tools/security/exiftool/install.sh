#!/usr/bin/env bash

_TOOL="exiftool"
_PKG="exiftool"

install_exiftool() {
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

uninstall_exiftool() {
  log_info "Removendo $_TOOL..."
  if pkg uninstall -y "$_PKG" 2>/dev/null || apt remove -y "$_PKG" 2>/dev/null; then
    log_success "$_TOOL removido"
    return 0
  fi
  log_error "Falha ao remover $_TOOL"
  return 1
}

update_exiftool() {
  log_info "Atualizando exiftool..."
  if pkg install -y exiftool 2>/dev/null || apt install -y exiftool 2>/dev/null; then
    log_success "exiftool atualizado"
    return 0
  fi
  log_error "Falha ao atualizar exiftool"
  return 1
}

reinstall_exiftool() {
  uninstall_exiftool || [[ $? -eq 2 ]] || return 1

  install_exiftool
}
