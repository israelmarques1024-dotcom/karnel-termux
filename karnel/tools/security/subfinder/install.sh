#!/usr/bin/env bash

_SUBFINDER_MARKER="$PREFIX/share/karnel-installers/subfinder"
_SUBFINDER_VERSION="2.6.6"

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

install_subfinder() (
  if command -v subfinder &>/dev/null; then
    if ! installer_file_owned "$PREFIX/bin/subfinder" "$_SUBFINDER_MARKER"; then
      log_info "subfinder já está instalado"
      return 2
    fi
  fi
  log_info "Instalando subfinder..."
  if [ ! -f "$_SUBFINDER_MARKER" ] &&
    { pkg install -y subfinder 2>/dev/null || apt install -y subfinder 2>/dev/null; }; then
    local bin; bin="$(command -v subfinder)"
    [ -n "$bin" ] && sha256sum "$bin" > "$_SUBFINDER_MARKER" 2>/dev/null
    log_success "subfinder instalado"
    return 0
  fi

  command -v unzip >/dev/null 2>&1 || pkg install -y unzip >/dev/null 2>&1 || {
    log_error "unzip indisponível; não foi possível extrair subfinder"
    return 1
  }

  local arch asset checksum url tmpdir archive staged_bin
  arch=$(_subfinder_arch) || { log_error "Arquitetura não suportada"; return 1; }
  [[ "$arch" == armv7 ]] && arch="arm"
  asset="subfinder_${_SUBFINDER_VERSION}_linux_${arch}.zip"
  case "$arch" in
    arm64) checksum="3e3a08f7656e57824d7efc93703249ec46bbf5e716b0f287ec8947fa3a2bc9eb" ;;
    arm) checksum="ebea2eb7db80b711cb43c2cdbc903a3a60e03fb212ec2482c5f3122d54dc6fc3" ;;
    amd64) checksum="6fda32fe1f5750e63fa07c112b1b615d033e425c6dc6659ed8ec61035eb8eba2" ;;
    *) return 1 ;;
  esac
  url="https://github.com/projectdiscovery/subfinder/releases/download/v${_SUBFINDER_VERSION}/$asset"

  tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/subfinder.XXXXXX") || return 1
  staged_bin=""
  trap 'rm -rf "$tmpdir"; [ -z "$staged_bin" ] || rm -f "$staged_bin"' EXIT
  archive="$tmpdir/subfinder.zip"
  curl -fsSL "$url" -o "$archive" 2>/dev/null || return 1
  verify_sha256 "$archive" "$checksum" || return 1
  safe_extract_zip "$archive" "$tmpdir/extracted" || return 1
  staged_bin="$tmpdir/extracted/subfinder"
  [ -f "$staged_bin" ] || { log_error "Pacote subfinder inválido"; return 1; }
  mkdir -p "$PREFIX/bin" || return 1
  activate_installer_file "$staged_bin" "$PREFIX/bin/subfinder" "$_SUBFINDER_MARKER" || return 1
  staged_bin=""
  log_success "subfinder instalado"
  return 0
)

uninstall_subfinder() {
  log_info "Removendo subfinder..."
  if [ -f "$_SUBFINDER_MARKER" ]; then
    [ "$(sha256sum "$PREFIX/bin/subfinder" 2>/dev/null)" = "$(<"$_SUBFINDER_MARKER")" ] && rm -f "$PREFIX/bin/subfinder"
    rm -f "$_SUBFINDER_MARKER"
  fi
  log_success "subfinder removido"
}

update_subfinder() {
  install_subfinder
}

reinstall_subfinder() {
  install_subfinder
}
