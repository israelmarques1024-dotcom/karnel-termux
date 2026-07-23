#!/usr/bin/env bash

_ENUM4LINUX_DIR="$PREFIX/share/enum4linux"

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
  if git clone --depth 1 https://github.com/CiscoCXSecurity/enum4linux "$_ENUM4LINUX_DIR" 2>/dev/null; then
    chmod +x "$_ENUM4LINUX_DIR/enum4linux.pl"
    ln -sf "$_ENUM4LINUX_DIR/enum4linux.pl" "$PREFIX/bin/enum4linux"
    log_success "enum4linux instalado"
    return 0
  fi
  log_error "Falha ao instalar enum4linux"
  return 1
}

uninstall_enum4linux() {
  log_info "Removendo enum4linux..."
  rm -f "$PREFIX/bin/enum4linux"
  rm -rf "$_ENUM4LINUX_DIR"
  log_success "enum4linux removido"
}

update_enum4linux() {
  if [ -d "$_ENUM4LINUX_DIR" ]; then
    git -C "$_ENUM4LINUX_DIR" pull
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
