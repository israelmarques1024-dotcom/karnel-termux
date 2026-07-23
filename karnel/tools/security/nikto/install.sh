#!/usr/bin/env bash

_NIKTO_DIR="$PREFIX/share/nikto"

install_nikto() {
  if command -v nikto &>/dev/null; then
    log_info "nikto já está instalado"
    return 2
  fi
  log_info "Instalando nikto..."
  if pkg install -y nikto 2>/dev/null || apt install -y nikto 2>/dev/null; then
    log_success "nikto instalado"
    return 0
  fi
  if git clone --depth 1 https://github.com/sullo/nikto "$_NIKTO_DIR" 2>/dev/null; then
    ln -sf "$_NIKTO_DIR/program/nikto.pl" "$PREFIX/bin/nikto"
    chmod +x "$PREFIX/bin/nikto"
    log_success "nikto instalado"
    return 0
  fi
  log_error "Falha ao instalar nikto"
  return 1
}

uninstall_nikto() {
  log_info "Removendo nikto..."
  rm -f "$PREFIX/bin/nikto"
  rm -rf "$_NIKTO_DIR"
  log_success "nikto removido"
}

update_nikto() {
  if [ -d "$_NIKTO_DIR" ]; then
    git -C "$_NIKTO_DIR" pull
    log_success "nikto atualizado"
    return 0
  fi
  log_warn "nikto não encontrado"
  return 1
}

reinstall_nikto() {
  uninstall_nikto
  install_nikto
}
