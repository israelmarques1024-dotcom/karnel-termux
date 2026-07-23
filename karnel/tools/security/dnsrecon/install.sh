#!/usr/bin/env bash

_DNSRECON_DIR="$PREFIX/share/dnsrecon"

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
  if git clone --depth 1 https://github.com/darkoperator/dnsrecon "$_DNSRECON_DIR" 2>/dev/null; then
    pip install -r "$_DNSRECON_DIR/requirements.txt" 2>/dev/null
    chmod +x "$_DNSRECON_DIR/dnsrecon.py"
    ln -sf "$_DNSRECON_DIR/dnsrecon.py" "$PREFIX/bin/dnsrecon"
    log_success "dnsrecon instalado"
    return 0
  fi
  log_error "Falha ao instalar dnsrecon"
  return 1
}

uninstall_dnsrecon() {
  log_info "Removendo dnsrecon..."
  rm -f "$PREFIX/bin/dnsrecon"
  rm -rf "$_DNSRECON_DIR"
  log_success "dnsrecon removido"
}

update_dnsrecon() {
  if [ -d "$_DNSRECON_DIR" ]; then
    git -C "$_DNSRECON_DIR" pull
    pip install -r "$_DNSRECON_DIR/requirements.txt" 2>/dev/null
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
