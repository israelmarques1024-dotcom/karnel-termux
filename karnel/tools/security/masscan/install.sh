#!/usr/bin/env bash

_MASSCAN_DIR="$PREFIX/share/masscan"

install_masscan() {
  if command -v masscan &>/dev/null; then
    log_info "masscan já está instalado"
    return 2
  fi
  log_info "Instalando masscan..."
  if pkg install -y masscan 2>/dev/null || apt install -y masscan 2>/dev/null; then
    log_success "masscan instalado"
    return 0
  fi

  pkg install -y git make clang 2>/dev/null

  if [ -d "$_MASSCAN_DIR" ]; then
    rm -rf "$_MASSCAN_DIR"
  fi

  git clone --depth 1 https://github.com/robertdavidgraham/masscan "$_MASSCAN_DIR" 2>/dev/null || return 1
  make -C "$_MASSCAN_DIR" -j4 2>/dev/null || return 1
  cp "$_MASSCAN_DIR/bin/masscan" "$PREFIX/bin/masscan"
  chmod +x "$PREFIX/bin/masscan"
  log_success "masscan instalado"
  return 0
}

uninstall_masscan() {
  log_info "Removendo masscan..."
  rm -f "$PREFIX/bin/masscan"
  rm -rf "$_MASSCAN_DIR"
  log_success "masscan removido"
}

update_masscan() {
  if [ -d "$_MASSCAN_DIR" ]; then
    git -C "$_MASSCAN_DIR" pull
    make -C "$_MASSCAN_DIR" -j4 2>/dev/null
    cp "$_MASSCAN_DIR/bin/masscan" "$PREFIX/bin/masscan"
    log_success "masscan atualizado"
    return 0
  fi
  install_masscan
}

reinstall_masscan() {
  uninstall_masscan
  install_masscan
}
