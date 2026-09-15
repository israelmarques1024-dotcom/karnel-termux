#!/usr/bin/env bash

_THEHARVESTER_DIR="$PREFIX/share/theharvester"
_THEHARVESTER_REPO="https://github.com/laramies/theHarvester.git"
_THEHARVESTER_COMMIT="6c5f3a388489b66297c8abab67c31a8a9c5927bd"

install_theharvester() {
  if command -v theharvester &>/dev/null; then
    log_info "theharvester já está instalado"
    return 2
  fi
  log_info "Instalando theHarvester..."
  if pkg install -y theharvester 2>/dev/null || apt install -y theharvester 2>/dev/null; then
    log_success "theharvester instalado"
    return 0
  fi
  command -v git >/dev/null 2>&1 || pkg install -y git >/dev/null 2>&1 || {
    log_error "git é necessário para instalar o theharvester via repositório"
    return 1
  }
  if install_pinned_git_repo "$_THEHARVESTER_REPO" "$_THEHARVESTER_COMMIT" "$_THEHARVESTER_DIR"; then
    pip install -r "$_THEHARVESTER_DIR/requirements/base.txt" 2>>"$LOG_FILE" || return 1
    chmod +x "$_THEHARVESTER_DIR/theHarvester.py"
    ln -sf "$_THEHARVESTER_DIR/theHarvester.py" "$PREFIX/bin/theharvester"
    : > "$_THEHARVESTER_DIR/.karnel-wrapper"
    log_success "theharvester instalado"
    return 0
  fi
  log_error "Falha ao instalar theHarvester"
  return 1
}

uninstall_theharvester() {
  log_info "Removendo theHarvester..."
  if [ -f "$_THEHARVESTER_DIR/.karnel-wrapper" ]; then
    [ "$(readlink "$PREFIX/bin/theharvester")" = "$_THEHARVESTER_DIR/theHarvester.py" ] && rm -f "$PREFIX/bin/theharvester"
    rm -rf "$_THEHARVESTER_DIR"
  fi
  log_success "theharvester removido"
}

update_theharvester() {
  if [ -d "$_THEHARVESTER_DIR" ]; then
    _pinned_git_repo_owned "$_THEHARVESTER_DIR" "$_THEHARVESTER_REPO" ||
      { [ -f "$_THEHARVESTER_DIR/.karnel-wrapper" ] && _adopt_pinned_git_repo "$_THEHARVESTER_DIR" "$_THEHARVESTER_REPO"; } || return 1
    install_pinned_git_repo "$_THEHARVESTER_REPO" "$_THEHARVESTER_COMMIT" "$_THEHARVESTER_DIR" || return 1
    : > "$_THEHARVESTER_DIR/.karnel-wrapper"
    pip install -r "$_THEHARVESTER_DIR/requirements/base.txt" 2>>"$LOG_FILE" || return 1
    log_success "theharvester atualizado"
    return 0
  fi
  log_warn "theharvester não encontrado"
  return 1
}

reinstall_theharvester() {
  uninstall_theharvester
  install_theharvester
}
