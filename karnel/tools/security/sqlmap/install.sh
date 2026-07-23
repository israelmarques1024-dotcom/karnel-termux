#!/usr/bin/env bash

_SQLMAP_DIR="$PREFIX/share/sqlmap"

install_sqlmap() {
  if command -v sqlmap &>/dev/null; then
    log_info "sqlmap já está instalado"
    return 2
  fi
  log_info "Instalando sqlmap..."
  if pkg install -y sqlmap 2>/dev/null || apt install -y sqlmap 2>/dev/null; then
    log_success "sqlmap instalado"
    return 0
  fi
  if git clone --depth 1 https://github.com/sqlmapproject/sqlmap "$_SQLMAP_DIR" 2>/dev/null; then
    ln -sf "$_SQLMAP_DIR/sqlmap.py" "$PREFIX/bin/sqlmap"
    chmod +x "$PREFIX/bin/sqlmap"
    log_success "sqlmap instalado"
    return 0
  fi
  log_error "Falha ao instalar sqlmap"
  return 1
}

uninstall_sqlmap() {
  log_info "Removendo sqlmap..."
  rm -f "$PREFIX/bin/sqlmap"
  rm -rf "$_SQLMAP_DIR"
  log_success "sqlmap removido"
}

update_sqlmap() {
  if [ -d "$_SQLMAP_DIR" ]; then
    git -C "$_SQLMAP_DIR" pull
    log_success "sqlmap atualizado"
    return 0
  fi
  log_warn "sqlmap não encontrado"
  return 1
}

reinstall_sqlmap() {
  uninstall_sqlmap
  install_sqlmap
}
