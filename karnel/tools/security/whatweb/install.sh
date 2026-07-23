#!/usr/bin/env bash

_WHATWEB_DIR="$PREFIX/share/whatweb"

install_whatweb() {
  if command -v whatweb &>/dev/null; then
    log_info "whatweb já está instalado"
    return 2
  fi
  log_info "Instalando whatweb..."
  if pkg install -y whatweb 2>/dev/null || apt install -y whatweb 2>/dev/null; then
    log_success "whatweb instalado"
    return 0
  fi
  if git clone --depth 1 https://github.com/urbanadventurer/WhatWeb "$_WHATWEB_DIR" 2>/dev/null; then
    ln -sf "$_WHATWEB_DIR/whatweb" "$PREFIX/bin/whatweb"
    chmod +x "$PREFIX/bin/whatweb"
    log_success "whatweb instalado"
    return 0
  fi
  log_error "Falha ao instalar whatweb"
  return 1
}

uninstall_whatweb() {
  log_info "Removendo whatweb..."
  rm -f "$PREFIX/bin/whatweb"
  rm -rf "$_WHATWEB_DIR"
  log_success "whatweb removido"
}

update_whatweb() {
  if [ -d "$_WHATWEB_DIR" ]; then
    git -C "$_WHATWEB_DIR" pull
    log_success "whatweb atualizado"
    return 0
  fi
  log_warn "whatweb não encontrado"
  return 1
}

reinstall_whatweb() {
  uninstall_whatweb
  install_whatweb
}
