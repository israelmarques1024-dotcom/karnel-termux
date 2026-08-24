#!/usr/bin/env bash

_SQLMAP_DIR="$PREFIX/share/sqlmap"
_SQLMAP_REPO="https://github.com/sqlmapproject/sqlmap.git"
_SQLMAP_COMMIT="ebf4b483371c3894913c6a8f9aafbbd484e44c80"

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
  command -v git >/dev/null 2>&1 || pkg install -y git >/dev/null 2>&1 || {
    log_error "git é necessário para instalar o sqlmap via repositório"
    return 1
  }
  if install_pinned_git_repo "$_SQLMAP_REPO" "$_SQLMAP_COMMIT" "$_SQLMAP_DIR"; then
    ln -sf "$_SQLMAP_DIR/sqlmap.py" "$PREFIX/bin/sqlmap"
    chmod +x "$PREFIX/bin/sqlmap"
    : > "$_SQLMAP_DIR/.karnel-wrapper"
    log_success "sqlmap instalado"
    return 0
  fi
  log_error "Falha ao instalar sqlmap"
  return 1
}

uninstall_sqlmap() {
  log_info "Removendo sqlmap..."
  if [ -f "$_SQLMAP_DIR/.karnel-wrapper" ]; then
    [ "$(readlink "$PREFIX/bin/sqlmap")" = "$_SQLMAP_DIR/sqlmap.py" ] && rm -f "$PREFIX/bin/sqlmap"
    rm -rf "$_SQLMAP_DIR"
  fi
  log_success "sqlmap removido"
}

update_sqlmap() {
  if [ -d "$_SQLMAP_DIR" ]; then
    _pinned_git_repo_owned "$_SQLMAP_DIR" "$_SQLMAP_REPO" ||
      { [ -f "$_SQLMAP_DIR/.karnel-wrapper" ] && _adopt_pinned_git_repo "$_SQLMAP_DIR" "$_SQLMAP_REPO"; } || return 1
    install_pinned_git_repo "$_SQLMAP_REPO" "$_SQLMAP_COMMIT" "$_SQLMAP_DIR" || return 1
    : > "$_SQLMAP_DIR/.karnel-wrapper"
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
