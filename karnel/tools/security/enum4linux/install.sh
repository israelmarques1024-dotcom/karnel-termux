#!/usr/bin/env bash

_ENUM4LINUX_DIR="$PREFIX/share/enum4linux"
_ENUM4LINUX_REPO="https://github.com/CiscoCXSecurity/enum4linux.git"
_ENUM4LINUX_COMMIT="0a5b7d48a97bbda648aaf7ace47a9e4f736ef8d7"

install_enum4linux() {
  if command -v enum4linux &>/dev/null; then
    log_info "enum4linux já está instalado"
    return 2
  fi
  log_info "Instalando enum4linux..."
  if pkg install -y enum4linux 2>/dev/null || apt install -y enum4linux 2>/dev/null; then
    log_success "enum4linux instalado"
    return 0
  fi
  if install_pinned_git_repo "$_ENUM4LINUX_REPO" "$_ENUM4LINUX_COMMIT" "$_ENUM4LINUX_DIR"; then
    chmod +x "$_ENUM4LINUX_DIR/enum4linux.pl"
    ln -sf "$_ENUM4LINUX_DIR/enum4linux.pl" "$PREFIX/bin/enum4linux"
    : > "$_ENUM4LINUX_DIR/.karnel-wrapper"
    log_success "enum4linux instalado"
    return 0
  fi
  log_error "Falha ao instalar enum4linux"
  return 1
}

uninstall_enum4linux() {
  log_info "Removendo enum4linux..."
  if [ -f "$_ENUM4LINUX_DIR/.karnel-wrapper" ]; then
    [ "$(readlink "$PREFIX/bin/enum4linux")" = "$_ENUM4LINUX_DIR/enum4linux.pl" ] && rm -f "$PREFIX/bin/enum4linux"
    rm -rf "$_ENUM4LINUX_DIR"
  fi
  log_success "enum4linux removido"
}

update_enum4linux() {
  if [ -d "$_ENUM4LINUX_DIR" ]; then
    _pinned_git_repo_owned "$_ENUM4LINUX_DIR" "$_ENUM4LINUX_REPO" ||
      { [ -f "$_ENUM4LINUX_DIR/.karnel-wrapper" ] && _adopt_pinned_git_repo "$_ENUM4LINUX_DIR" "$_ENUM4LINUX_REPO"; } || return 1
    install_pinned_git_repo "$_ENUM4LINUX_REPO" "$_ENUM4LINUX_COMMIT" "$_ENUM4LINUX_DIR" || return 1
    : > "$_ENUM4LINUX_DIR/.karnel-wrapper"
    log_success "enum4linux atualizado"
    return 0
  fi
  log_warn "enum4linux não encontrado"
  return 1
}

reinstall_enum4linux() {
  uninstall_enum4linux
  install_enum4linux
}
