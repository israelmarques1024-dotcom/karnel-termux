#!/usr/bin/env bash

_MASSCAN_DIR="${KARNEL_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data}/tools/masscan"
_MASSCAN_REPO="https://github.com/robertdavidgraham/masscan.git"
_MASSCAN_COMMIT="94e118ccd26c2fb263fb2fe731043f7b3240723c"

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

  if [ -e "$_MASSCAN_DIR" ]; then
    log_error "Karnel source directory already exists: $_MASSCAN_DIR"
    return 1
  fi

  mkdir -p "$(dirname "$_MASSCAN_DIR")" || return 1
  install_pinned_git_repo "$_MASSCAN_REPO" "$_MASSCAN_COMMIT" "$_MASSCAN_DIR" || return 1
  make -C "$_MASSCAN_DIR" -j4 2>/dev/null || return 1
  install -m 755 "$_MASSCAN_DIR/bin/masscan" "$PREFIX/bin/masscan"
  chmod +x "$PREFIX/bin/masscan"
  sha256sum "$PREFIX/bin/masscan" > "$_MASSCAN_DIR/.karnel-wrapper"
  log_success "masscan instalado"
  return 0
}

uninstall_masscan() {
  log_info "Removendo masscan..."
  if [ -f "$_MASSCAN_DIR/.karnel-wrapper" ]; then
    [ "$(sha256sum "$PREFIX/bin/masscan" 2>/dev/null)" = "$(<"$_MASSCAN_DIR/.karnel-wrapper")" ] && rm -f "$PREFIX/bin/masscan"
    rm -rf "$_MASSCAN_DIR"
  fi
  log_success "masscan removido"
}

update_masscan() {
  if [ -d "$_MASSCAN_DIR" ]; then
    _pinned_git_repo_owned "$_MASSCAN_DIR" "$_MASSCAN_REPO" ||
      { [ -f "$_MASSCAN_DIR/.karnel-wrapper" ] && _adopt_pinned_git_repo "$_MASSCAN_DIR" "$_MASSCAN_REPO"; } || return 1
    install_pinned_git_repo "$_MASSCAN_REPO" "$_MASSCAN_COMMIT" "$_MASSCAN_DIR" || return 1
    make -C "$_MASSCAN_DIR" -j4 2>/dev/null || return 1
  install -m 755 "$_MASSCAN_DIR/bin/masscan" "$PREFIX/bin/masscan" || return 1
    sha256sum "$PREFIX/bin/masscan" > "$_MASSCAN_DIR/.karnel-wrapper" || return 1
    log_success "masscan atualizado"
    return 0
  fi
  install_masscan
}

reinstall_masscan() {
  uninstall_masscan
  install_masscan
}
