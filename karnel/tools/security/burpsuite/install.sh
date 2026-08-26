#!/usr/bin/env bash

_BURP_DIR="$PREFIX/share/burpsuite"
_BURP_JAR="burpsuite_community.jar"
_BURP_VERSION="2026.7.3"
_BURP_SHA256="c8262dc5426f38bedc490d66c5d21b6ff77d6dc6d85cefe6a66c882690134069"

_burpsuite_owned() {
  installer_file_owned "$PREFIX/bin/burpsuite" "$_BURP_DIR/.karnel-wrapper"
}

install_burpsuite() (
  if command -v burpsuite &>/dev/null; then
    if ! _burpsuite_owned; then
      log_info "burpsuite já está instalado"
      return 2
    fi
  fi
  log_info "Instalando Burp Suite..."

  if [ ! -f "$_BURP_DIR/.karnel-wrapper" ] &&
    { pkg install -y burpsuite 2>/dev/null || apt install -y burpsuite 2>/dev/null; }; then
    log_success "burpsuite instalado"
    return 0
  fi

  pkg install -y curl openjdk-17 2>/dev/null

  local url tmpdir staged_dir wrapper old_dir wrapper_backup
  url="https://portswigger.net/burp/releases/download?product=community&type=Jar&version=${_BURP_VERSION}"
  tmpdir=$(mktemp -d "${TMPDIR:-${KARNEL_CACHE:-$HOME/.cache/karnel}}/burpsuite.XXXXXX") || return 1
  trap 'rm -rf "$tmpdir"' EXIT
  staged_dir="$tmpdir/data"
  mkdir -p "$staged_dir" "$PREFIX/bin" "$(dirname "$_BURP_DIR")" || return 1
  curl -fsSL "$url" -o "$staged_dir/$_BURP_JAR" || return 1
  verify_sha256 "$staged_dir/$_BURP_JAR" "$_BURP_SHA256" || return 1
  wrapper="$tmpdir/burpsuite"
  cat >"$wrapper" << 'SCRIPT'
#!/usr/bin/env bash
exec java -jar "$PREFIX/share/burpsuite/burpsuite_community.jar" "$@"
SCRIPT
  chmod 755 "$wrapper" || return 1

  old_dir="${_BURP_DIR}.previous.$$"
  wrapper_backup=""
  if [ -e "$_BURP_DIR" ]; then
    _burpsuite_owned || { log_error "Instalação Burp Suite existente não pertence ao Karnel"; return 1; }
    mv "$_BURP_DIR" "$old_dir" || return 1
  fi
  if [ -e "$PREFIX/bin/burpsuite" ]; then
    wrapper_backup=$(mktemp "$PREFIX/bin/.burpsuite-backup.XXXXXX") || {
      [ ! -e "$old_dir" ] || mv "$old_dir" "$_BURP_DIR"
      return 1
    }
    if ! mv "$PREFIX/bin/burpsuite" "$wrapper_backup"; then
      rm -f "$wrapper_backup"
      [ ! -e "$old_dir" ] || mv "$old_dir" "$_BURP_DIR"
      return 1
    fi
  fi
  if ! mv "$staged_dir" "$_BURP_DIR" || ! mv "$wrapper" "$PREFIX/bin/burpsuite" ||
    ! sha256sum "$PREFIX/bin/burpsuite" >"$_BURP_DIR/.karnel-wrapper"; then
    rm -rf "$_BURP_DIR"
    rm -f "$PREFIX/bin/burpsuite"
    [ ! -e "$old_dir" ] || mv "$old_dir" "$_BURP_DIR"
    [ -z "$wrapper_backup" ] || mv "$wrapper_backup" "$PREFIX/bin/burpsuite"
    log_error "Falha ao instalar burpsuite"
    return 1
  fi
  rm -rf "$old_dir"
  [ -z "$wrapper_backup" ] || rm -f "$wrapper_backup"
  log_success "burpsuite instalado"
)

uninstall_burpsuite() {
  log_info "Removendo Burp Suite..."
  if [ -f "$_BURP_DIR/.karnel-wrapper" ]; then
    [ "$(sha256sum "$PREFIX/bin/burpsuite" 2>/dev/null)" = "$(<"$_BURP_DIR/.karnel-wrapper")" ] && rm -f "$PREFIX/bin/burpsuite"
    rm -rf "$_BURP_DIR"
  fi
  log_success "burpsuite removido"
}

update_burpsuite() {
  install_burpsuite
}

reinstall_burpsuite() {
  install_burpsuite
}
