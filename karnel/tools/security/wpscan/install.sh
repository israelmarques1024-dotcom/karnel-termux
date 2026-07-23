#!/usr/bin/env bash

install_wpscan() {
  if command -v wpscan &>/dev/null; then
    log_info "wpscan já está instalado"
    return 2
  fi
  log_info "Instalando wpscan..."
  if pkg install -y wpscan 2>/dev/null || apt install -y wpscan 2>/dev/null; then
    log_success "wpscan instalado"
    return 0
  fi
  if gem install wpscan 2>/dev/null; then
    log_success "wpscan instalado"
    return 0
  fi
  log_error "Falha ao instalar wpscan"
  return 1
}

uninstall_wpscan() {
  log_info "Removendo wpscan..."
  gem uninstall wpscan 2>/dev/null || true
  log_success "wpscan removido"
}

update_wpscan() {
  log_info "Atualizando wpscan..."
  gem update wpscan 2>/dev/null || log_warn "Falha ao atualizar wpscan"
  return 2
}

reinstall_wpscan() {
  uninstall_wpscan
  install_wpscan
}
