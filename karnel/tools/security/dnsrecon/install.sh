#!/usr/bin/env bash

_DNSRECON_DIR="$PREFIX/share/dnsrecon"
_DNSRECON_REPO="https://github.com/darkoperator/dnsrecon.git"
_DNSRECON_COMMIT="0cbe45aee8cc472c18a44c9c169508b6fee2009f"

install_dnsrecon() {
  if command -v dnsrecon &>/dev/null; then
    log_info "dnsrecon já está instalado"
    return 2
  fi
  log_info "Instalando dnsrecon..."
  if pkg install -y dnsrecon 2>/dev/null || apt install -y dnsrecon 2>/dev/null; then
    log_success "dnsrecon instalado"
    return 0
  fi
  command -v git >/dev/null 2>&1 || pkg install -y git >/dev/null 2>&1 || {
    log_error "git é necessário para instalar o dnsrecon via repositório"
    return 1
  }
  if install_pinned_git_repo "$_DNSRECON_REPO" "$_DNSRECON_COMMIT" "$_DNSRECON_DIR"; then
    pip install -r "$_DNSRECON_DIR/requirements.txt" 2>>"$LOG_FILE" || return 1
    chmod +x "$_DNSRECON_DIR/dnsrecon.py"
    ln -sf "$_DNSRECON_DIR/dnsrecon.py" "$PREFIX/bin/dnsrecon"
    : > "$_DNSRECON_DIR/.karnel-wrapper"
    log_success "dnsrecon instalado"
    return 0
  fi
  log_error "Falha ao instalar dnsrecon"
  return 1
}

uninstall_dnsrecon() {
  log_info "Removendo dnsrecon..."
  if [ -f "$_DNSRECON_DIR/.karnel-wrapper" ]; then
    [ "$(readlink "$PREFIX/bin/dnsrecon")" = "$_DNSRECON_DIR/dnsrecon.py" ] && rm -f "$PREFIX/bin/dnsrecon"
    rm -rf "$_DNSRECON_DIR"
  fi
  log_success "dnsrecon removido"
}

update_dnsrecon() {
  if [ -d "$_DNSRECON_DIR" ]; then
    _pinned_git_repo_owned "$_DNSRECON_DIR" "$_DNSRECON_REPO" ||
      { [ -f "$_DNSRECON_DIR/.karnel-wrapper" ] && _adopt_pinned_git_repo "$_DNSRECON_DIR" "$_DNSRECON_REPO"; } || return 1
    install_pinned_git_repo "$_DNSRECON_REPO" "$_DNSRECON_COMMIT" "$_DNSRECON_DIR" || return 1
    : > "$_DNSRECON_DIR/.karnel-wrapper"
    pip install -r "$_DNSRECON_DIR/requirements.txt" 2>>"$LOG_FILE" || return 1
    log_success "dnsrecon atualizado"
    return 0
  fi
  log_warn "dnsrecon não encontrado"
  return 1
}

reinstall_dnsrecon() {
  uninstall_dnsrecon
  install_dnsrecon
}
