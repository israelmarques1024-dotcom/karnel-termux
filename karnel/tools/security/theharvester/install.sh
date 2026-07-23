#!/usr/bin/env bash

_THEHARVESTER_DIR="$PREFIX/share/theharvester"

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
  if git clone --depth 1 https://github.com/laramies/theHarvester "$_THEHARVESTER_DIR" 2>/dev/null; then
    pip install -r "$_THEHARVESTER_DIR/requirements/base.txt" 2>/dev/null
    chmod +x "$_THEHARVESTER_DIR/theHarvester.py"
    ln -sf "$_THEHARVESTER_DIR/theHarvester.py" "$PREFIX/bin/theharvester"
    log_success "theharvester instalado"
    return 0
  fi
  log_error "Falha ao instalar theHarvester"
  return 1
}

uninstall_theharvester() {
  log_info "Removendo theHarvester..."
  rm -f "$PREFIX/bin/theharvester"
  rm -rf "$_THEHARVESTER_DIR"
  log_success "theharvester removido"
}

update_theharvester() {
  if [ -d "$_THEHARVESTER_DIR" ]; then
    git -C "$_THEHARVESTER_DIR" pull
    pip install -r "$_THEHARVESTER_DIR/requirements/base.txt" 2>/dev/null
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
