#!/usr/bin/env bash

_subfinder_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    aarch64) echo "arm64" ;;
    armv7l|arm) echo "armv7" ;;
    x86_64) echo "amd64" ;;
    *) echo ""; return 1 ;;
  esac
}

install_subfinder() {
  if command -v subfinder &>/dev/null; then
    log_info "subfinder já está instalado"
    return 2
  fi
  log_info "Instalando subfinder..."
  if pkg install -y subfinder 2>/dev/null || apt install -y subfinder 2>/dev/null; then
    log_success "subfinder instalado"
    return 0
  fi

  local arch version url
  arch=$(_subfinder_arch) || { log_error "Arquitetura não suportada"; return 1; }
  version=$(curl -fsSL "https://api.github.com/repos/projectdiscovery/subfinder/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  [ -z "$version" ] && version="v2.6.6"
  url="https://github.com/projectdiscovery/subfinder/releases/download/${version}/subfinder_${version#v}_linux_${arch}.zip"

  curl -fsSL "$url" -o /tmp/subfinder.zip 2>/dev/null || return 1
  unzip -o /tmp/subfinder.zip -d /tmp/subfinder 2>/dev/null
  mv /tmp/subfinder/subfinder "$PREFIX/bin/subfinder" 2>/dev/null
  chmod +x "$PREFIX/bin/subfinder"
  rm -rf /tmp/subfinder /tmp/subfinder.zip
  log_success "subfinder instalado"
  return 0
}

uninstall_subfinder() {
  log_info "Removendo subfinder..."
  rm -f "$PREFIX/bin/subfinder"
  log_success "subfinder removido"
}

update_subfinder() {
  uninstall_subfinder
  install_subfinder
}

reinstall_subfinder() {
  uninstall_subfinder
  install_subfinder
}
