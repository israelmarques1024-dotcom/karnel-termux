#!/usr/bin/env bash

_ZAP_DIR="$PREFIX/share/zap"
_ZAP_VERSION="2.16.1"
_ZAP_SHA256="5b2eb8319b085121a6e8ad50d69d67dbef8c867166f71a937bfc888d247a2ac1"

_zap_owned() {
  installer_file_owned "$PREFIX/bin/zap" "$_ZAP_DIR/.karnel-wrapper"
}

install_zap() (
  if command -v zap &>/dev/null; then
    if ! _zap_owned; then
      log_info "zap já está instalado"
      return 2
    fi
  fi
  log_info "Instalando ZAP (Zed Attack Proxy)..."

  if [ ! -f "$_ZAP_DIR/.karnel-wrapper" ] &&
    { pkg install -y zaproxy 2>/dev/null || apt install -y zaproxy 2>/dev/null; }; then
    log_success "zap instalado"
    return 0
  fi

  pkg install -y curl openjdk-17 2>/dev/null

  local arch tmpdir archive zap_home wrapper old_dir wrapper_backup
  arch="$(uname -m)"
  case "$arch" in
    aarch64|armv7l|arm|x86_64) ZAP_ASSET="ZAP_${_ZAP_VERSION}_Linux.tar.gz" ;;
    *) log_error "Arquitetura não suportada: $arch"; return 1 ;;
  esac

  local url="https://github.com/zaproxy/zaproxy/releases/download/v${_ZAP_VERSION}/$ZAP_ASSET"

  tmpdir=$(mktemp -d "${TMPDIR:-${KARNEL_CACHE:-$HOME/.cache/karnel}}/zap.XXXXXX") || {
    log_error "Falha ao criar diretório temporário"
    return 1
  }
  wrapper=""
  trap 'rm -rf "$tmpdir"; [ -z "$wrapper" ] || rm -f "$wrapper"' EXIT
  archive="$tmpdir/zap.tar.gz"

  curl -fsSL "$url" -o "$archive" 2>/dev/null || {
    log_error "Falha ao baixar ZAP"
    return 1
  }

  verify_sha256 "$archive" "$_ZAP_SHA256" || return 1
  safe_extract_tar "$archive" "$tmpdir/extracted" || {
    log_error "Falha ao extrair ZAP"
    return 1
  }
  zap_home=$(find "$tmpdir/extracted" -mindepth 1 -maxdepth 1 -type d -name 'ZAP*' -print -quit)
  if [ -z "$zap_home" ] || [ ! -x "$zap_home/zap.sh" ]; then
    log_error "Pacote ZAP inválido"
    return 1
  fi

  mkdir -p "$(dirname "$_ZAP_DIR")" "$PREFIX/bin" || return 1
  wrapper=$(mktemp "$PREFIX/bin/.zap.XXXXXX") || return 1
  cat > "$wrapper" << 'SCRIPT'
#!/usr/bin/env bash
ZAP_HOME=$(find "$PREFIX/share/zap" -maxdepth 1 -type d -name "ZAP*" | head -1)
exec "$ZAP_HOME/zap.sh" "$@"
SCRIPT
  chmod +x "$wrapper" || return 1
  old_dir="${_ZAP_DIR}.previous.$$"
  wrapper_backup=""
  if [ -e "$_ZAP_DIR" ]; then
    _zap_owned || { log_error "Instalação ZAP existente não pertence ao Karnel"; return 1; }
    mv "$_ZAP_DIR" "$old_dir" || return 1
  fi
  if [ -e "$PREFIX/bin/zap" ]; then
    wrapper_backup=$(mktemp "$PREFIX/bin/.zap-backup.XXXXXX") || {
      [ ! -e "$old_dir" ] || mv "$old_dir" "$_ZAP_DIR"
      return 1
    }
    if ! mv "$PREFIX/bin/zap" "$wrapper_backup"; then
      rm -f "$wrapper_backup"
      [ ! -e "$old_dir" ] || mv "$old_dir" "$_ZAP_DIR"
      return 1
    fi
  fi
  if ! mkdir "$_ZAP_DIR" || ! mv "$zap_home" "$_ZAP_DIR/" ||
    ! mv -f "$wrapper" "$PREFIX/bin/zap" ||
    ! sha256sum "$PREFIX/bin/zap" >"$_ZAP_DIR/.karnel-wrapper"; then
    rm -rf "$_ZAP_DIR"
    rm -f "$PREFIX/bin/zap"
    [ ! -e "$old_dir" ] || mv "$old_dir" "$_ZAP_DIR"
    [ -z "$wrapper_backup" ] || mv "$wrapper_backup" "$PREFIX/bin/zap"
    log_error "Falha ao instalar ZAP"
    return 1
  fi
  wrapper=""
  rm -rf "$old_dir"
  [ -z "$wrapper_backup" ] || rm -f "$wrapper_backup"
  log_success "zap instalado"
  return 0
)

uninstall_zap() {
  log_info "Removendo ZAP..."
  if [ -f "$_ZAP_DIR/.karnel-wrapper" ]; then
    [ "$(sha256sum "$PREFIX/bin/zap" 2>/dev/null)" = "$(<"$_ZAP_DIR/.karnel-wrapper")" ] && rm -f "$PREFIX/bin/zap"
    rm -rf "$_ZAP_DIR"
  fi
  log_success "zap removido"
}

update_zap() {
  install_zap
}

reinstall_zap() {
  install_zap
}
