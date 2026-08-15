#!/usr/bin/env bash

_NIKTO_DIR="$PREFIX/share/nikto"
_NIKTO_REPO="https://github.com/sullo/nikto.git"
_NIKTO_COMMIT="d5067406bc0902f8174cb5f8d595f637951974ce"

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
  if install_pinned_git_repo "$_NIKTO_REPO" "$_NIKTO_COMMIT" "$_NIKTO_DIR"; then
    ln -sf "$_NIKTO_DIR/program/nikto.pl" "$PREFIX/bin/nikto"
    chmod +x "$PREFIX/bin/nikto"
    : > "$_NIKTO_DIR/.karnel-wrapper"
    log_success "nikto instalado"
    return 0
  fi
  log_error "Falha ao instalar nikto"
  return 1
}

uninstall_nikto() {
  log_info "Removendo nikto..."
  if [ -f "$_NIKTO_DIR/.karnel-wrapper" ]; then
    [ "$(readlink "$PREFIX/bin/nikto")" = "$_NIKTO_DIR/program/nikto.pl" ] && rm -f "$PREFIX/bin/nikto"
    rm -rf "$_NIKTO_DIR"
  fi
  log_success "nikto removido"
}

update_nikto() {
  if [ -d "$_NIKTO_DIR" ]; then
    _pinned_git_repo_owned "$_NIKTO_DIR" "$_NIKTO_REPO" ||
      { [ -f "$_NIKTO_DIR/.karnel-wrapper" ] && _adopt_pinned_git_repo "$_NIKTO_DIR" "$_NIKTO_REPO"; } || return 1
    install_pinned_git_repo "$_NIKTO_REPO" "$_NIKTO_COMMIT" "$_NIKTO_DIR" || return 1
    : > "$_NIKTO_DIR/.karnel-wrapper"
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
