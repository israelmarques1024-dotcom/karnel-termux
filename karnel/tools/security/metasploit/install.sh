#!/usr/bin/env bash

METASPLOIT_DIR="${KARNEL_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/karnel-data}/tools/metasploit-framework"
METASPLOIT_REPO="https://github.com/rapid7/metasploit-framework.git"
METASPLOIT_COMMIT="9f74eb0a48ca7f8039c2618e359c2e80f998ac89"

install_metasploit() {
  if command -v msfconsole &>/dev/null; then
    log_info "metasploit já está instalado"
    return 2
  fi
  log_info "Instalando Metasploit Framework..."

  if pkg install -y metasploit 2>/dev/null || apt install -y metasploit 2>/dev/null; then
    log_success "metasploit instalado"
    return 0
  fi

  pkg install -y ruby git curl autoconf bison flex openssl libxml2 libxslt libyaml ncurses zlib 2>/dev/null

  mkdir -p "$(dirname "$METASPLOIT_DIR")" || return 1
  install_pinned_git_repo "$METASPLOIT_REPO" "$METASPLOIT_COMMIT" "$METASPLOIT_DIR" || {
    log_error "Falha ao instalar fonte fixada do Metasploit"
    return 1
  }

  cd "$METASPLOIT_DIR"
  gem install bundler 2>>"$LOG_FILE" || return 1
  bundle install --jobs 4 2>>"$LOG_FILE" || return 1

  for bin in msfconsole msfvenom msfrpc msfrpcd msfdb; do
    cat > "$PREFIX/bin/$bin" << BINEOF
#!/usr/bin/env bash
exec bundle exec ruby "$METASPLOIT_DIR/$bin" "\$@"
BINEOF
    chmod +x "$PREFIX/bin/$bin"
    sha256sum "$PREFIX/bin/$bin" > "$METASPLOIT_DIR/.karnel-wrapper-$bin"
  done
  : > "$METASPLOIT_DIR/.karnel-installed"

  log_success "metasploit instalado"
  return 0
}

uninstall_metasploit() {
  log_info "Removendo Metasploit..."
  for bin in msfconsole msfvenom msfrpc msfrpcd msfdb; do
    if [ -f "$METASPLOIT_DIR/.karnel-wrapper-$bin" ]; then
      [ "$(sha256sum "$PREFIX/bin/$bin" 2>/dev/null)" = "$(<"$METASPLOIT_DIR/.karnel-wrapper-$bin")" ] && rm -f "$PREFIX/bin/$bin"
    fi
  done
  [ -f "$METASPLOIT_DIR/.karnel-installed" ] && rm -rf "$METASPLOIT_DIR"
  log_success "metasploit removido"
}

update_metasploit() {
  if [ -d "$METASPLOIT_DIR" ]; then
    _pinned_git_repo_owned "$METASPLOIT_DIR" "$METASPLOIT_REPO" ||
      { [ -f "$METASPLOIT_DIR/.karnel-installed" ] && _adopt_pinned_git_repo "$METASPLOIT_DIR" "$METASPLOIT_REPO"; } || return 1
    install_pinned_git_repo "$METASPLOIT_REPO" "$METASPLOIT_COMMIT" "$METASPLOIT_DIR" || return 1
    cd "$METASPLOIT_DIR" && bundle install --jobs 4 2>>"$LOG_FILE" || return 1
    for bin in msfconsole msfvenom msfrpc msfrpcd msfdb; do
      sha256sum "$PREFIX/bin/$bin" > "$METASPLOIT_DIR/.karnel-wrapper-$bin"
    done
    : > "$METASPLOIT_DIR/.karnel-installed"
    log_success "metasploit atualizado"
    return 0
  fi
  log_warn "metasploit não encontrado"
  return 1
}

reinstall_metasploit() {
  uninstall_metasploit
  install_metasploit
}
