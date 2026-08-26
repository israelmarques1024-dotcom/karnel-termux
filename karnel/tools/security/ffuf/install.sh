#!/usr/bin/env bash

_FFUF_MARKER="$PREFIX/share/karnel-installers/ffuf"
_FFUF_VERSION="2.1.0"

inc_ffuf_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    aarch64) echo "arm64" ;;
    armv7l|arm) echo "arm" ;;
    x86_64) echo "amd64" ;;
    *) echo ""; return 1 ;;
  esac
}

_download_ffuf() (
  local arch asset url checksum tmpdir archive staged_bin
  arch=$(inc_ffuf_arch) || return 1
  [[ "$arch" == arm ]] && arch="armv6"
  asset="ffuf_${_FFUF_VERSION}_linux_${arch}.tar.gz"
  case "$arch" in
    arm64) checksum="6ae920d09d5202762fca21967a460c6fb88135bdfa806bee4d3d2c430dcedeea" ;;
    armv6) checksum="b9d4b7e485f098bbcd2a61ba0c8304aac8634c71a7a0d29ad243aaf7db16ec9b" ;;
    amd64) checksum="fc2c82736c14dcbea4daf3d3cf3878c1c4773008ba45c2bc0fceba7d17b40bb5" ;;
    *) return 1 ;;
  esac
  url="https://github.com/ffuf/ffuf/releases/download/v${_FFUF_VERSION}/$asset"
  tmpdir=$(mktemp -d "${TMPDIR:-${KARNEL_CACHE:-$HOME/.cache/karnel}}/ffuf.XXXXXX") || return 1
  staged_bin=""
  trap 'rm -rf "$tmpdir"; [ -z "$staged_bin" ] || rm -f "$staged_bin"' EXIT
  archive="$tmpdir/ffuf.tar.gz"
  curl -fsSL "$url" -o "$archive" || return 1
  verify_sha256 "$archive" "$checksum" || return 1
  safe_extract_tar "$archive" "$tmpdir/extracted" || return 1
  staged_bin="$tmpdir/extracted/ffuf"
  [ -f "$staged_bin" ] || { log_error "Pacote ffuf inválido"; return 1; }
  mkdir -p "$PREFIX/bin" || return 1
  activate_installer_file "$staged_bin" "$PREFIX/bin/ffuf" "$_FFUF_MARKER" || return 1
  staged_bin=""
  return 0
)

install_ffuf() {
  if command -v ffuf &>/dev/null; then
    log_info "ffuf já está instalado"
    return 2
  fi
  log_info "Instalando ffuf..."
  if pkg install -y ffuf 2>/dev/null || apt install -y ffuf 2>/dev/null; then
    log_success "ffuf instalado"
    return 0
  fi
  if _download_ffuf; then
    log_success "ffuf instalado"
    return 0
  fi
  log_error "Falha ao instalar ffuf"
  return 1
}

uninstall_ffuf() {
  log_info "Removendo ffuf..."
  if [ -f "$_FFUF_MARKER" ]; then
    [ "$(sha256sum "$PREFIX/bin/ffuf" 2>/dev/null)" = "$(<"$_FFUF_MARKER")" ] && rm -f "$PREFIX/bin/ffuf"
    rm -f "$_FFUF_MARKER"
  fi
  log_success "ffuf removido"
}

update_ffuf() {
  _download_ffuf
}

reinstall_ffuf() {
  _download_ffuf
}
