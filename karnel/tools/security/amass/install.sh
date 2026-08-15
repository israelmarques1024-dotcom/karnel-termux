#!/usr/bin/env bash

_AMASS_MARKER="$PREFIX/share/karnel-installers/amass"
_AMASS_VERSION="4.2.0"

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

install_amass() (
  if command -v amass &>/dev/null; then
    if ! installer_file_owned "$PREFIX/bin/amass" "$_AMASS_MARKER"; then
      log_info "amass já está instalado"
      return 2
    fi
  fi
  log_info "Instalando amass..."
  if [ ! -f "$_AMASS_MARKER" ] &&
    { pkg install -y amass 2>/dev/null || apt install -y amass 2>/dev/null; }; then
    log_success "amass instalado"
    return 0
  fi

  local arch asset checksum url tmpdir archive amass_bin staged_bin
  arch=$(_amass_arch) || { log_error "Arquitetura não suportada"; return 1; }
  [[ "$arch" == armv7 ]] && arch="arm"
  asset="amass_Linux_${arch}.zip"
  case "$arch" in
    arm64) checksum="f9677acd8599417cccac1cf15e623e68f2610f8425eaff77bf7a4364f1a1f0d3" ;;
    arm) checksum="ea2eacb07d4b1fbe1d8db075a3c497746b8268894797b573c86451b5628f8f5c" ;;
    amd64) checksum="abef624f84b21fb45d4b9d39693863c6bf4e9ddb94830f797c129d03937a7f03" ;;
    *) return 1 ;;
  esac
  url="https://github.com/owasp-amass/amass/releases/download/v${_AMASS_VERSION}/$asset"

  tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/amass.XXXXXX") || return 1
  staged_bin=""
  trap 'rm -rf "$tmpdir"; [ -z "$staged_bin" ] || rm -f "$staged_bin"' EXIT
  archive="$tmpdir/amass.zip"
  curl -fsSL "$url" -o "$archive" 2>/dev/null || return 1
  verify_sha256 "$archive" "$checksum" || return 1
  safe_extract_zip "$archive" "$tmpdir/extracted" || return 1
  amass_bin=$(find "$tmpdir/extracted" -name amass -type f -print -quit 2>/dev/null)
  [ -n "$amass_bin" ] || { log_error "Pacote amass inválido"; return 1; }
  mkdir -p "$PREFIX/bin" || return 1
  staged_bin="$amass_bin"
  activate_installer_file "$staged_bin" "$PREFIX/bin/amass" "$_AMASS_MARKER" || return 1
  staged_bin=""
  log_success "amass instalado"
  return 0
)

uninstall_amass() {
  log_info "Removendo amass..."
  if [ -f "$_AMASS_MARKER" ]; then
    [ "$(sha256sum "$PREFIX/bin/amass" 2>/dev/null)" = "$(<"$_AMASS_MARKER")" ] && rm -f "$PREFIX/bin/amass"
    rm -f "$_AMASS_MARKER"
  fi
  log_success "amass removido"
}

update_amass() {
  install_amass
}

reinstall_amass() {
  install_amass
}
