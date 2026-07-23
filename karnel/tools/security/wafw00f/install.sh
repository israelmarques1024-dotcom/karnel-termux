#!/usr/bin/env bash

install_wafw00f() {
  if command -v wafw00f &>/dev/null; then
    log_info "wafw00f já está instalado"
    return 2
  fi
  log_info "Instalando wafw00f..."
  if pkg install -y wafw00f 2>/dev/null || apt install -y wafw00f 2>/dev/null; then
    log_success "wafw00f instalado"
    return 0
  fi
  if pip install wafw00f 2>/dev/null; then
    log_success "wafw00f instalado"
    return 0
  fi
  log_error "Falha ao instalar wafw00f"
  return 1
}

uninstall_wafw00f() {
  log_info "Removendo wafw00f..."
  pip uninstall -y wafw00f 2>/dev/null || true
  log_success "wafw00f removido"
}

update_wafw00f() {
  log_info "Atualizando wafw00f..."
  pip install --upgrade wafw00f 2>/dev/null || log_warn "Falha ao atualizar wafw00f"
  return 2
}

reinstall_wafw00f() {
  uninstall_wafw00f
  install_wafw00f
}
