#!/usr/bin/env bash

_WHATWEB_DIR="$PREFIX/share/whatweb"
_WHATWEB_REPO="https://github.com/urbanadventurer/WhatWeb.git"
_WHATWEB_COMMIT="d279d93042d034f3fd29d5a893d44ccc0595d3f8"

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
  if install_pinned_git_repo "$_WHATWEB_REPO" "$_WHATWEB_COMMIT" "$_WHATWEB_DIR"; then
    ln -sf "$_WHATWEB_DIR/whatweb" "$PREFIX/bin/whatweb"
    chmod +x "$PREFIX/bin/whatweb"
    : > "$_WHATWEB_DIR/.karnel-wrapper"
    log_success "whatweb instalado"
    return 0
  fi
  log_error "Falha ao instalar whatweb"
  return 1
}

uninstall_whatweb() {
  log_info "Removendo whatweb..."
  if [ -f "$_WHATWEB_DIR/.karnel-wrapper" ]; then
    [ "$(readlink "$PREFIX/bin/whatweb")" = "$_WHATWEB_DIR/whatweb" ] && rm -f "$PREFIX/bin/whatweb"
    rm -rf "$_WHATWEB_DIR"
  fi
  log_success "whatweb removido"
}

update_whatweb() {
  if [ -d "$_WHATWEB_DIR" ]; then
    _pinned_git_repo_owned "$_WHATWEB_DIR" "$_WHATWEB_REPO" ||
      { [ -f "$_WHATWEB_DIR/.karnel-wrapper" ] && _adopt_pinned_git_repo "$_WHATWEB_DIR" "$_WHATWEB_REPO"; } || return 1
    install_pinned_git_repo "$_WHATWEB_REPO" "$_WHATWEB_COMMIT" "$_WHATWEB_DIR" || return 1
    : > "$_WHATWEB_DIR/.karnel-wrapper"
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
