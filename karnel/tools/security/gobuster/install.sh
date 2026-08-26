#!/usr/bin/env bash

_GOBUSTER_VERSION="3.6.0"
_GOBUSTER_DIR="$PREFIX/share/gobuster"
_GOBUSTER_MARKER="$PREFIX/share/karnel-installers/gobuster"

_install_gobuster_bin() (
  local arch asset checksum tmpdir archive staged_bin
  arch="$(uname -m)"
  case "$arch" in
    aarch64) _GOBUSTER_ARCH="arm64" ;;
    armv7l|arm) log_error "Gobuster v${_GOBUSTER_VERSION} não fornece binário ARM de 32 bits autenticado"; return 1 ;;
    x86_64) _GOBUSTER_ARCH="x86_64" ;;
    *) log_error "Arquitetura não suportada: $arch"; return 1 ;;
  esac
  asset="gobuster_Linux_${_GOBUSTER_ARCH}.tar.gz"
  case "$_GOBUSTER_ARCH" in
    arm64) checksum="9d6c93ea27fa0477a8f7b57a4c495c8c91490d76805180c18b9d77bfc4f61b55" ;;
    x86_64) checksum="871be404ce5f80c96b864586b3caa90f894598d1a8222ae316c19e5f70e04cfc" ;;
  esac
  local url="https://github.com/OJ/gobuster/releases/download/v${_GOBUSTER_VERSION}/$asset"
  tmpdir=$(mktemp -d "${TMPDIR:-${KARNEL_CACHE:-$HOME/.cache/karnel}}/gobuster.XXXXXX") || return 1
  staged_bin=""
  trap 'rm -rf "$tmpdir"; [ -z "$staged_bin" ] || rm -f "$staged_bin"' EXIT
  archive="$tmpdir/gobuster.tar.gz"
  curl -fsSL "$url" -o "$archive" || return 1
  verify_sha256 "$archive" "$checksum" || return 1
  safe_extract_tar "$archive" "$tmpdir/extracted" || return 1
  staged_bin="$tmpdir/extracted/gobuster"
  [ -f "$staged_bin" ] || { log_error "Pacote gobuster inválido"; return 1; }
  mkdir -p "$PREFIX/bin" || return 1
  activate_installer_file "$staged_bin" "$PREFIX/bin/gobuster" "$_GOBUSTER_MARKER" || return 1
  staged_bin=""
  return 0
)

install_gobuster() {
  if command -v gobuster &>/dev/null; then
    if ! installer_file_owned "$PREFIX/bin/gobuster" "$_GOBUSTER_MARKER"; then
      log_info "gobuster já está instalado"
      return 2
    fi
  fi
  log_info "Instalando gobuster..."
  if [ ! -f "$_GOBUSTER_MARKER" ] &&
    { pkg install -y gobuster 2>/dev/null || apt install -y gobuster 2>/dev/null; }; then
    log_success "gobuster instalado"
    return 0
  fi
  if _install_gobuster_bin; then
    log_success "gobuster instalado"
    return 0
  fi
  log_error "Falha ao instalar gobuster"
  return 1
}

uninstall_gobuster() {
  log_info "Removendo gobuster..."
  if [ -f "$_GOBUSTER_MARKER" ]; then
    [ "$(sha256sum "$PREFIX/bin/gobuster" 2>/dev/null)" = "$(<"$_GOBUSTER_MARKER")" ] && rm -f "$PREFIX/bin/gobuster"
    rm -f "$_GOBUSTER_MARKER"
  fi
  log_success "gobuster removido"
}

update_gobuster() {
  log_info "gobuster atualizado via download"
  install_gobuster
}

reinstall_gobuster() {
  install_gobuster
}
