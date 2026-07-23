#!/usr/bin/env bash

_amass_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    aarch64) echo "arm64" ;;
    armv7l|arm) echo "armv7" ;;
    x86_64) echo "amd64" ;;
    *) echo ""; return 1 ;;
  esac
}

install_amass() {
  if command -v amass &>/dev/null; then
    log_info "amass já está instalado"
    return 2
  fi
  log_info "Instalando amass..."
  if pkg install -y amass 2>/dev/null || apt install -y amass 2>/dev/null; then
    log_success "amass instalado"
    return 0
  fi

  local arch version url
  arch=$(_amass_arch) || { log_error "Arquitetura não suportada"; return 1; }
  version=$(curl -fsSL "https://api.github.com/repos/owasp-amass/amass/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  [ -z "$version" ] && version="v4.2.0"
  url="https://github.com/owasp-amass/amass/releases/download/${version}/amass_linux_${arch}.zip"

  curl -fsSL "$url" -o /tmp/amass.zip 2>/dev/null || return 1
  unzip -o /tmp/amass.zip -d /tmp/amass 2>/dev/null
  local amass_bin
  amass_bin=$(find /tmp/amass -name "amass" -type f 2>/dev/null | head -1)
  if [ -n "$amass_bin" ]; then
    mv "$amass_bin" "$PREFIX/bin/amass"
    chmod +x "$PREFIX/bin/amass"
  fi
  rm -rf /tmp/amass /tmp/amass.zip
  log_success "amass instalado"
  return 0
}

uninstall_amass() {
  log_info "Removendo amass..."
  rm -f "$PREFIX/bin/amass"
  log_success "amass removido"
}

update_amass() {
  uninstall_amass
  install_amass
}

reinstall_amass() {
  uninstall_amass
  install_amass
}
